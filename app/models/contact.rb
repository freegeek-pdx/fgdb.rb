class Contact < ActiveRecord::Base
  acts_as_userstamp

  has_and_belongs_to_many :contact_types
  has_many :contact_methods
  has_many :contact_method_types, :through => :contact_methods
  has_many :volunteer_tasks, :order => 'date_performed DESC'
  has_many :disbursements
  has_many :sales
  has_many :donations
  has_many :spec_sheets
  has_one :user
  has_one :contact_duplicate
  belongs_to :contract
  has_many :library_events

  validates_presence_of :postal_code
  #validates_presence_of :created_by
  before_save :remove_empty_contact_methods
  before_save :ensure_consistent_contact_types

  def checked_out
    @checked_out ||= Copy.checked_out_to(self.id)
  end

  def overdue
    @overdue ||= Copy.overdue_for_contact(self.id)
  end

  def lost
    @lost ||= Copy.lost_by(self.id)
  end

  def checked_out_n_good
    checked_out - (overdue + lost)
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
      connection.execute("UPDATE volunteer_tasks SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE donations SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE sales SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE disbursements SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
      connection.execute("UPDATE spec_sheets SET contact_id = #{self.id} WHERE contact_id = #{other.id}")
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
      connection.execute("DELETE FROM contacts WHERE id = #{other.id}")
    end
    if self.contact_duplicate && ContactDuplicate.find_all_by_dup_check(self.contact_duplicate.dup_check).length == 1
      ContactDuplicate.delete(self.contact_duplicate)
    end
  end

  def contact
    self
  end

  def phone_numbers
    a = []
    contact_methods.map {|x|
      a << x.value if (x.contact_method_type.description =~ /phone|fax/ and x.ok == true)
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

  def find_volunteer_tasks(cutoff = nil)
    # if it's named volunteer_tasks it breaks everything
    if cutoff
      conditions = [ "contact_id = ? AND date_performed >= ?", id, cutoff ]
    else
      conditions = [ "contact_id = ?", id ]
    end
    VolunteerTask.find(:all,
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

  def hours_effective
    find_volunteer_tasks(date_of_last_adoption).inject(0.0) do |total,task|
      total += task.effective_duration
    end
  end

  # effective for adoption
  def adoption_hours
    hours_effective
  end

  def effective_discount_hours
    last_ninety_days_of_effective_hours
  end

  def last_ninety_days_of_volunteer_tasks
    find_volunteer_tasks(Date.today - 90)
  end

  def last_ninety_days_of_actual_hours
    hours_actual(true)
  end

  def last_ninety_days_of_effective_hours
    last_ninety_days_of_volunteer_tasks.inject(0.0) {|tot,task|
      tot + task.effective_duration
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

  def default_discount_schedule
    if contact_types.include?(ContactType.find_by_name("bulk_buyer"))
      DiscountSchedule.find_by_name("bulk")
    elsif effective_discount_hours >= 4.0
      DiscountSchedule.find_by_name("volunteer")
    else
      DiscountSchedule.find_by_name("no_discount")
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
    return last_gizmos("disbursements")
  end

  def last_sales
    return last_gizmos("sales")
  end

  def last_donations
    return last_gizmos("donations")
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
  def last_gizmos(table)
    # figure out how to use a prepared statement here
    return self.connection.execute(
                                   "select gt.id, gt.description, sum(ge.gizmo_count)
       from gizmo_types gt
            join gizmo_events ge on ge.gizmo_type_id=gt.id
            join #{table} t on ge.#{table.singularize}_id=t.id
       where t.contact_id=#{self.id}
             and t.created_at > now()-'1@month'::interval
       group by 1,2").to_a.map{|hash| [hash["description"],hash["sum"]]}
  end

  def last_of_an_association(assoc)
    #:MC: optimize this into sql
    self.send(assoc).sort_by {|rec| rec.created_at}.last
  end

  def remove_empty_contact_methods
    for contact_method in contact_methods
      if contact_method.value.nil? or contact_method.value.empty?
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
      find(:all, {:limit => 5, :conditions => conditions, :order => "sort_name"}.merge(options))
    end

    def search_by_type(type, query, options = {})
      if query.to_i.to_s == query
        # allow searches by id
        search(query, options)
      else
        query = prepare_query(query)
        query += " AND types:\"*#{type}*\""
        search(query, options)
      end
    end

    protected

    def prepare_query(q)
      if q.to_i.to_s == q
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
