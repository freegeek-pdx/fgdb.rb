class Contact < ActiveRecord::Base
  acts_as_userstamp

  has_many :points_traded_away, :class_name => "PointsTrade", :foreign_key => "from_contact_id"
  has_many :points_traded_to, :class_name => "PointsTrade", :foreign_key => "to_contact_id"

  has_many :assignments

  has_and_belongs_to_many :contact_types
  has_many :contact_methods
  has_many :contact_method_types, :through => :contact_methods
  has_many :volunteer_tasks, :order => 'date_performed DESC'
  has_many :volunteer_task_types, :through => :volunteer_tasks
  has_many :disbursements
  has_many :sales
  has_many :donations
  has_many :builder_tasks
  has_one :user
  has_one :contact_duplicate
  belongs_to :contract
  has_many :gizmo_returns
  has_one :worker
  has_one :tech_support_note
  validates_numericality_of :birthday_year, :greater_than_or_equal_to => 1902, :less_than => 2038, :allow_nil => true

  def intern_title
    [self.volunteer_intern_title.to_s, "Intern"].select{|x| x.length > 0}.join(" ")
  end

  def merge_ts_notes
    ActiveRecord::Base.transaction do
      first_note = self.tech_support_note

      if first_note
        max_up = first_note.updated_at
        max_up_u = first_note.updated_by
        min_c = first_note.created_at
        min_c_u = first_note.created_by

        TechSupportNote.find_all_by_contact_id(self.id).each do |n|
          if n.id != first_note.id
            first_note.notes += "\n----\n#{n.notes}"
            if n.updated_at && (max_up.nil? || n.updated_at > max_up)
              max_up = n.updated_at
              max_up_u = n.updated_by
            end
            if n.created_at && (min_c.nil? || n.created_at < min_c)
              min_c = n.created_at
              min_c_u = n.created_by
            end
            n.destroy
          end
        end

        first_note.created_by = min_c_u
        first_note.created_at = min_c
        first_note.updated_by = max_up_u
        first_note.updated_at = max_up
        first_note.save!
      end
    end
  end

  def tech_support_notes
    self.tech_support_note.notes if self.tech_support_note
  end

  def birthday_year_before_type_cast # WTF..
    self.birthday ? self.birthday.year : nil
  end
  alias_method :birthday_year, :birthday_year_before_type_cast

  has_many :disciplinary_actions, :autosave => true

  def unresolved_donations
    donations.select(&:has_unresolved_invoice?)
  end

  validate :name_provided
  def name_provided
    unless $civicrm_mode
      errors.add('organization', 'name must be provided for organizations') if is_organization? and (organization.nil? or organization.empty?)
      errors.add('first_name', 'or surname must be provided for individuals') if is_person? and (first_name.nil? or first_name.empty?) and (surname.nil? or surname.empty?)
    end
  end

  def self.born_on_or_before
    return nil if not Default['minimum_volunteer_age']
    Date.today.advance(:years => -1 * Default['minimum_volunteer_age'].to_i)
  end

  def is_birthday?
    return false if self.birthday.nil?
    tod = Date.today
    tod.day == birthday.day and tod.month == birthday.month
  end

  def is_old_enough?
    return true if self.birthday.nil? or self.class.born_on_or_before.nil?
    ctt = ContactType.find_by_name('allow_without_adult')
    return true if ctt and self.contact_types.include?(ctt)
    return self.birthday <= self.class.born_on_or_before
  end

  def has_areas_disciplined_from?
    self.areas_disciplined_from.length > 0
  end

  def areas_disciplined_from
    self.disciplinary_actions.not_disabled.map(&:disciplinary_action_areas).flatten.uniq.sort_by(&:name)
  end

  validates_presence_of :postal_code, :on => :create, :unless => :foreign_person_or_civicrm?
  #validates_presence_of :created_by
  before_save :remove_empty_contact_methods
  before_save :ensure_consistent_contact_types
  before_save :strip_some_fields
  validates_associated :user
  after_save :add_to_processor_daemon

  validates_length_of :first_name, :maximum => 25
  validates_length_of :middle_name, :maximum => 25
  validates_length_of :surname, :maximum => 50
  validates_length_of :organization, :maximum => 100
  validates_length_of :extra_address, :maximum => 52
  validates_length_of :address, :maximum => 52
  validates_length_of :city, :maximum => 30
  validates_length_of :state_or_province, :maximum => 15
  validates_length_of :postal_code, :maximum => 25
  validates_length_of :country, :maximum => 100

  def foreign_person_or_civicrm?
    foreign_person? or $civicrm_mode
  end

  def foreign_person?
    Default["country"] != self.country
  end

  def to_s
    display_name
  end

  def condition_to_s
    display_name
  end

  def self.allow_shared
    true
  end

  # used to find when a volunteer is scheduled for more than 2 shifts
  def schedule_counts
    h = {}
    return h if self.is_organization? # organizations may schedule as much as they like
    assns = self.assignments.is_after_today.roster_is_limited_by_program.not_cancelled
    assns.each do |a|
      progs = a.real_programs
      progs.each do |p|
        h[p] ||= 0
        h[p] += 1
      end
    end
    h
  end

  def birthday=(bday)
    begin
      parsed = Date.parse(bday)
      write_attribute(:birthday, parsed)
      return bday
    rescue
      return nil
    end
  end

  def mailing_list_email
    list = ContactMethodType.email_types_ordered.map{|x| x.id}
    list = list.reverse if self.is_organization?
    result = self.contact_methods.select{|x| x.ok}.select{|x| list.include?(x.contact_method_type_id)}.sort{|a,b| r = (list.index(a.contact_method_type_id) <=> list.index(b.contact_method_type_id)); r == 0 ? ((b.updated_at || b.created_at) <=> (a.updated_at || a.created_at)) : r}.first
    result ? result.value : nil
  end

  def to_privileges
    ["contact_#{self.id}", "has_contact"]
  end

  def update_all_task_counts
    self.volunteer_task_types.each do |vtt|
      self.update_syseval_count(vtt.id)
    end
  end

  def update_syseval_count(vid)
    return unless vid
    c = ContactVolunteerTaskTypeCount.find_or_create_by_contact_id_and_volunteer_task_type_id(self.id, vid)
    vtt = VolunteerTaskType.find(vid)
    c.count = self.volunteer_tasks.for_type_id(vtt.id).count
    if vtt && vtt.name == 'sorting'
      # FIXME: generalize solution?
      vtt2 = VolunteerTaskType.find_by_name('receiving')
      c.count += self.volunteer_tasks.for_type_id(vtt2.id).count if vtt2
    end
    c.save!
  end

  def future_shifts
    self.assignments.on_or_after_today.not_cancelled.sort{|a,b| t = a.date <=> b.date; t == 0 ? a.start_time <=> b.start_time : t}
  end

  def scheduled_shifts
    a = future_shifts
    more = false
    if a.length > 5
      a = a[0,5]
      more = true
    end
    a = a.map{|x| x.description}
    a << "More.." if more # FIXME: this needs to be a link
    a.join("<br/>")
  end

  def all_points_trades
    self.points_traded_away + self.points_traded_to
  end

  def points(trade_id = nil)
    effective_hours = hours_effective
    max = Default['max_effective_hours'].to_f
    negative = points_traded_since_last_adoption("from", trade_id)
    positive = points_traded_since_last_adoption("to", trade_id)
    positive = positive - effective_points_traded_over_a_year_ago(trade_id)
    if positive < 0
      effective_hours = effective_hours + positive
      positive = 0
    end
    effective_hours = [effective_hours, max].min
    sum = effective_hours - negative + positive
    return sum
  end

  def effective_points_traded_over_a_year_ago(trade_id)
    points_traded_since_last_adoption("from", trade_id, 1.year.ago)
  end

  def cleanup_string(str)
    return nil if str.nil?
    str = str.strip
    str = str.gsub(/\s+/, " ")
    return str
  end

  def strip_some_fields
    self.first_name = cleanup_string(self.first_name)
    self.surname = cleanup_string(self.surname)
    self.middle_name = cleanup_string(self.middle_name)
    self.organization = cleanup_string(self.organization)
  end

  def fully_covered_
    case self.fully_covered
    when nil: 'nil'
    when true: "yes"
    when false: "no"
    end
  end

  def fully_covered_=(val)
    self.fully_covered={:nil => nil, :yes => true, :no => false}[val.to_sym]
  end

  def merge_these_in(arr)
    for other in arr
      raise if other.id == self.id
      connection.execute("UPDATE volunteer_tasks SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE tech_support_notes SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE donations SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE sales SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE disciplinary_actions SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE assignments SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE default_assignments SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE gizmo_returns SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE disbursements SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE builder_tasks SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE workers SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE points_trades SET from_contact_id = #{self.id} WHERE from_contact_id = #{other.id}")
      connection.execute("UPDATE points_trades SET to_contact_id = #{self.id} WHERE to_contact_id = #{other.id}")
      connection.execute("UPDATE recycling_shipments SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE contacts_mailings SET contact_id = NULL WHERE contact_id = #{other.id} AND mailing_id IN (SELECT mailing_id FROM contacts_mailings WHERE contact_id IN (#{self.id}, #{other.id}) GROUP BY mailing_id HAVING count(*) > 1)")
      connection.execute("UPDATE contacts_mailings SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE contacts SET created_at = (SELECT min(created_at) FROM contacts WHERE id IN (#{self.id}, #{other.id})) WHERE id = #{self.id}")
      self.notes = [self.notes, other.notes].uniq.delete_if{|x| x.nil?}.join("\n")
      self.save!
      connection.execute("UPDATE contacts SET updated_at = (SELECT max(updated_at) FROM contacts WHERE id IN (#{self.id}, #{other.id})) WHERE id = #{self.id}")
      connection.execute("UPDATE contact_methods SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      self.contact_types = (self.contact_types + other.contact_types).uniq
      if other.user and self.user
        self.user.merge_in(other.user)
        Contact.connection.execute("DELETE FROM users WHERE contact_id = #{other.id}")
      end
      if other.user and !self.user
        Contact.connection.execute("UPDATE users SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      end
      self.save!
      if other.contact_duplicate
        ContactDuplicate.delete(other.contact_duplicate)
      end
      connection.execute("DELETE FROM contact_volunteer_task_type_counts WHERE contact_id = #{other.id}")
      connection.execute("DELETE FROM contacts WHERE id = #{other.id}")
    end
    if self.contact_duplicate && ContactDuplicate.find_all_by_dup_check(self.contact_duplicate.dup_check).length == 1
      ContactDuplicate.delete(self.contact_duplicate)
    end
    self.update_all_task_counts
    self.merge_ts_notes
  end

  def contact
    self
  end

  def display_phone_numbers
    self.contact_methods.map{|x|
      (x.contact_method_type.description =~ /phone/ and !(x.contact_method_type.description =~ /emergency/) and x.ok == true) ? "#{x.contact_method_type.description}: #{x.value}" : nil
    }.select{|x| !x.nil?}.join(", ")
  end

  def phone_numbers
    a = []
    contact_methods.map {|x|
      a << x.value if (x.contact_method_type.description =~ /phone|fax/ and !(x.contact_method_type.description =~ /emergency/) and x.ok == true) # ruby apparently doesn't support negative lookbehinds..sadday :(
    }
    a
  end

  def phone_number
    phone_numbers.first
  end

  def is_organization?
    self.is_organization
  end

  def is_person?
    ! self.is_organization?
  end

  def uncompleted
    vt = volunteer_tasks.find_by_duration(nil)
    if not vt.nil? and vt.date_performed < 1.day.ago
      # evidentally they forgot to check out... make a new handler for this later.
      vt.destroy
      return nil
    else
      return vt
    end
  end

  def checked_in?
    not uncompleted.nil?
  end

  def check(options = {})
    if checked_in?
      task = uncompleted
      # since multiparameter attributes won't work w/ aliases, do it manually
      time_attrs = []
      for i in 1..5
        time_attrs << options.delete("end_time(#{i}i)").to_i
      end
      options[:end_time] = Time.local(*time_attrs)
      task.update_attributes(options)
    else
      task = VolunteerTask.new(options)
      volunteer_tasks << task
      task.save
    end
    return task
  end

  def hours_actual(last_ninety = false)
    tasks = last_ninety ? last_ninety_days_of_volunteer_tasks : volunteer_tasks
    tasks.inject(0.0) do |total,task|
      total += task.duration
    end
  end

  def find_volunteer_tasks(cutoff = nil, klass = VolunteerTask, contact_id_type = "", date_field = "date_performed", max = nil)
    # if it's named volunteer_tasks it breaks everything
    contact_id_type = contact_id_type + "_" if contact_id_type.length > 0
    if max and cutoff
      conditions = [ "#{contact_id_type}contact_id = ? AND #{date_field} >= ? AND #{date_field} < ?", id, cutoff, max ]
    elsif cutoff
      conditions = [ "#{contact_id_type}contact_id = ? AND #{date_field} >= ?", id, cutoff ]
    elsif max
      conditions = [ "#{contact_id_type}contact_id = ? AND #{date_field} < ?", id, max ]
    else
      conditions = [ "#{contact_id_type}contact_id = ?", id ]
    end
    klass.find(:all,
                       :conditions => conditions)
  end

  def date_of_last_adoption
    last_adoption = Disbursement.find(:first, :conditions => [ "(disbursement_type_id = ? OR disbursement_type_id = ?) AND contact_id = ?", DisbursementType.find_by_name("adoption").id, DisbursementType.find_by_name("build").id, id], :order => "disbursed_at DESC")
    if last_adoption
      return Date.parse(last_adoption.disbursed_at.to_s)
    else
      return nil
    end
  end

  def spec_sheets_since_last_adoption(action_name)
    BuilderTask.find(:all, :conditions => ["contact_id = ? AND builder_tasks.created_at > ? AND cashier_signed_off_by IS NOT NULL AND action_id = ?", self.id, date_of_last_adoption || Date.parse("2000-01-01"), Action.find_by_name(action_name).id])
  end

  def points_traded_since_last_adoption(type, trade_id = nil, after = nil)
    a = [date_of_last_adoption ? date_of_last_adoption + 1 : nil]
    if type == "from" and after.nil?
      a << (1.year.ago + 1).to_datetime # FIXME: Default variable?
    end
    date = a.select{|x| !x.nil?}.sort.last
    find_volunteer_tasks(date, PointsTrade, type, "created_at", after).delete_if{|x| !trade_id.nil? && x.id == trade_id}.inject(0.0) do |t,r|
      t += r.points
    end
  end

  def hours_effective
    find_volunteer_tasks(date_of_last_adoption).inject(0.0) do |total,task|
        total += task.effective_duration
    end
  end

  def hours_since_last_adoption
    find_volunteer_tasks(date_of_last_adoption).inject(0.0) do |total,task|
      total += task.duration
    end
  end

  def last_trade
    self.all_points_trades.sort_by(&:created_at).last
  end

  def date_of_last_trade
    last_trade.nil? ? nil : last_trade.created_at.to_date
  end

  def effective_discount_hours
    last_ninety_days_of_effective_hours
  end

  def last_ninety_days_of_volunteer_tasks
    find_volunteer_tasks(Date.today - Default['days_for_discount'].to_f)
  end

  def last_ninety_days_of_actual_hours
    hours_actual(true)
  end

  def last_ninety_days_of_effective_hours
    last_ninety_days_of_volunteer_tasks.inject(0.0) {|tot,task|
      tot + task.duration
    }
  end

  def last_few_volunteer_tasks
    volunteer_tasks.sort_by {|v_t| v_t.date_performed }[-3..-1]
  end

  def default_volunteer_task_type
    last_few = last_few_volunteer_tasks
    if( last_few.length > 1 and
        last_few.map {|v_t| v_t.volunteer_task_type}.uniq.length == 1 )
      return last_few.first.volunteer_task_type
    else
      return []
    end
  end

  def screen_sortby
    display_name
  end

  def last_volunteered_date
    begin
      raise ArgumentError unless self.id
      ret = (DB.exec("SELECT MAX(date_performed) AS max FROM volunteer_tasks WHERE contact_id = ?", self.id).to_a.first["max"])
      return ret ? Date.parse(ret).to_s : ""
    rescue ArgumentError
      return ""
    end
  end

  def last_donated_date
    begin
      raise ArgumentError unless self.id
      ret = (DB.exec("SELECT MAX(occurred_at) AS max FROM donations WHERE contact_id = ?", self.id).to_a.first["max"])
      return ret ? Date.parse(ret).to_s : ""
    rescue ArgumentError
      return ""
    end
  end

  def last_donated_contribution_only_date
    begin
      raise ArgumentError unless self.id
      ret = (DB.exec("SELECT MAX(occurred_at) AS max FROM donations WHERE contact_id = ? AND donations.id IN (SELECT DISTINCT donation_id FROM payments WHERE donation_id IS NOT NULL) AND donations.id NOT IN (SELECT DISTINCT donation_id FROM gizmo_events WHERE donation_id IS NOT NULL)", self.id).to_a.first["max"])
      return ret ? Date.parse(ret).to_s : ""
    rescue ArgumentError
      return ""
    end
  end

  def last_donated_gizmos_only_date
    begin
      raise ArgumentError unless self.id
      ret = DB.exec("SELECT MAX(occurred_at) AS max FROM donations WHERE contact_id = ? AND donations.id NOT IN (SELECT DISTINCT donation_id FROM payments WHERE donation_id IS NOT NULL) AND donations.id IN (SELECT DISTINCT donation_id FROM gizmo_events WHERE donation_id IS NOT NULL)", self.id).to_a.first["max"]
      return ret ? Date.parse(ret).to_s : ""
    rescue ArgumentError
      return ""
    end
  end

  def first_name_or_organization
    if is_organization
      return organization
    else
      return first_name
    end
  end

  def display_last_name_first
    if is_organization
      return organization
    else
      return "#{surname}, #{first_name}"
    end
  end

  def display_name
    if is_person?
      if(self.first_name || self.middle_name || self.surname)
        "%s %s %s" % [self.first_name, self.middle_name, self.surname]
      else
        '(person without name)'
      end
    else
      if self.organization && ! self.organization.empty?
        self.organization
      else
        '(organization without name)'
      end
    end
  end

  def short_address
    [address, extra_address, postal_code].join(', ')
  end

  def csz
    "#{city}, #{state_or_province}  #{postal_code}"
  end

  def p_id
    return ["Contact ##{self.id}"]
  end

  def display_name_address
    disp = []
    disp.concat(display_name.to_a) unless
      display_name.nil? or display_name.size == 0
    disp.concat(display_address.to_a) unless
      display_address.nil? or display_address.size == 0
    return disp
  end

  def display_address
    dispaddr = []
    dispaddr.push(address)
    dispaddr.push(extra_address) unless
      extra_address.nil? or extra_address == ''
    dispaddr.push(csz)
    dispaddr.push(country) unless
      country.nil? or country == '' or country.upcase =~ /^USA*$/
    return dispaddr
  end

  def types
    contact_types.join(' ')
  end

  def has_worker?
    ! self.worker.nil? && worker.effective_now?
  end

  def default_discount_schedule
    if effective_discount_hours >= Default['hours_for_discount'].to_f or self.has_worker?
      return "volunteer"
    else
      return "no_discount"
    end
  end

  def last_disbursement
    last_of_an_association('disbursements')
  end

  def last_sale
    last_of_an_association('sales')
  end

  def last_donation
    last_of_an_association('donations')
  end

  def last_disbursements
    return last_gizmos("disbursements", "2@year")
  end

  def last_sales
    return last_gizmos("sales")
  end

  def last_donations
    return last_gizmos("donations")
  end

  def last_gizmo_returns
    return last_gizmos("gizmo_returns")
  end

  def is_user?
    !!user
  end

  def is_user=(x)
  end

  def get_recent_sale_totals()
    x = self.connection.execute("
      SELECT COUNT(*),
             SUM(reported_discount_amount_cents),
             SUM(reported_amount_due_cents)
      FROM sales tx
      WHERE tx.created_at > now()-'90@day'::INTERVAL
            AND tx.contact_id=#{self.id}
      ")
    return {:count=>x[0][0],
      :discounted=>x[0][1],
      :total=>x[0][2]}
  end

  alias :is_user :is_user?

  private

  # returns the last gizmos associated with the given table
  # over the last month
  def last_gizmos(table, interval = "1@month" )
    # figure out how to use a prepared statement here
    return self.connection.execute(
                                   "select gt.id, gt.description, sum(ge.gizmo_count)
       from gizmo_types gt
            join gizmo_events ge on ge.gizmo_type_id=gt.id
            join #{table} t on ge.#{table.singularize}_id=t.id
       where t.contact_id=#{self.id}
             and t.created_at > now()-'#{interval}'::interval
       group by 1,2").to_a.map{|hash| [hash["description"],hash["sum"]]}
  end

  def last_of_an_association(assoc)
    #:MC: optimize this into sql
    self.send(assoc).sort_by {|rec| rec.created_at}.last
  end

  def remove_empty_contact_methods
    for contact_method in contact_methods
      if (contact_method.value.nil? or contact_method.value.empty?) && (contact_method.details.nil? or contact_method.details.empty?)
        contact_method.destroy
      end
    end
  end

  def ensure_consistent_contact_types
    types = contact_types.map {|ct| ct.name}
    if((types.include?("build") or types.include?("adopter")) and
       (! types.include?("volunteer")))
      contact_types << ContactType.find_by_name("volunteer")
    end
  end

  class << self
    # not ever used...but could be useful so I'm leaving it
    def find_by_type(type)
      sql = "SELECT contacts.* FROM contacts
                 LEFT JOIN contact_types_contacts AS j ON j.contact_id = contacts.id
                 LEFT JOIN contact_types AS c_t ON j.contact_type_id = c_t.id
               WHERE c_t.name = ? "
      find_by_sql([sql, type])
    end

    def search(query, options = {})
      # if the user added query wildcards or search metaterms, leave
      # be if not, assume it's better to bracket each word with
      # wildcards and join with ANDs.
      return [] unless query and query.length > 0
      conditions = prepare_query(query)
      find_by_conds(conditions, options)
    end

    def search_by_type(types, query, options = {})
      return [] unless query and query.length > 0
      if query.to_i.to_s == query
        # allow searches by id
        search(query, options)
      else
        conditions = prepare_query(query)
        conditions[0] += " AND contact_types.id IN (?)"
        conditions.push([types].flatten)
        return find_by_conds(conditions, options.merge(:joins => [:contact_types]))
      end
    end

    protected

    def find_by_conds(conditions, options)
      find(:all, {:limit => 5, :conditions => conditions, :order => "sort_name"}.merge(options))
    end

    def prepare_query(q)
      if q.to_i.to_s == q and q.to_i <= 2147483647 and q.to_i >= -2147483648
        return ["id = ?", q]
      end
      conds = [""]
      q.split.each do |word|
        conds[0] += "(surname ILIKE ? OR first_name ILIKE ? OR middle_name ILIKE ? OR organization ILIKE ?)"
        conds += ["%#{word}%"] * 4
        conds[0] += ' AND '
      end
      conds[0].sub!(/ AND $/, '')
      return conds
    end

  end # class << self

end
