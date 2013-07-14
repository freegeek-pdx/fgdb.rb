class Assignment < ActiveRecord::Base
  attr_accessor :redirect_to
  belongs_to :volunteer_shift
  has_one :volunteer_task_type, :through => :volunteer_shift, :source => :volunteer_task_type
  belongs_to :contact
  validates_presence_of :volunteer_shift
  validates_associated :volunteer_shift
  belongs_to :attendance_type
  belongs_to :call_status_type
  validates_presence_of :set_date, :if => :volshift_stuck
  validates_existence_of :contact, :allow_nil => true

  delegate :set_date, :set_date=, :to => :volunteer_shift
  delegate :set_description, :set_description=, :to => :volunteer_shift

  has_one :contact_volunteer_task_type_count, :conditions => 'contact_volunteer_task_type_counts.contact_id = #{defined?(attributes) ? contact_id : "assignments.contact_id"}', :through => :volunteer_shift, :source => :contact_volunteer_task_type_counts

  named_scope :no_call_no_show, :conditions => ['attendance_type_id = ?', AttendanceType.find_by_name("no call no show").id]
  named_scope :arrived, :conditions => ['attendance_type_id = ?', AttendanceType.find_by_name("arrived").id]
  named_scope :for_contact_id, lambda {|c| {:conditions => ['contact_id = ?', c]}}
  named_scope :updated_since, lambda {|u_date| u_date ? {:conditions => ['updated_at > ?', u_date]} : {:conditions => []}}
  named_scope :roster_is_limited_by_program, :conditions => ["roster_id IN (SELECT id FROM rosters WHERE limit_shift_signup_by_program = 't')"], :joins => [:volunteer_shift]
  named_scope :within_n_days_of, lambda{|n, x| {:conditions => ['date > ? AND date < ?', x - n, x + n], :joins => [:volunteer_shift => [:volunteer_event]]} }
  named_scope :for_sked_id,  lambda {|sked_id| {:conditions => ['roster_id in (?)', Sked.find_by_id(sked_id).roster_ids]}}

  def real_programs
    return [] unless self.volunteer_shift && self.volunteer_shift.roster
    return [] unless self.volunteer_shift.roster.limit_shift_signup_by_program
    return self.volunteer_shift.roster.skeds.select{|x| x.category_type == "Program"}.map{|x| x.name}
  end

  def nc_ns_since_last_arrived
    c = self.contact
    list = []
    return list unless c
    since_when = Assignment.for_contact_id(c.id).arrived.max
    since_when = since_when.date if since_when
    list = Assignment.for_contact_id(c.id).updated_since(since_when).no_call_no_show
    return list
  end

  def <=>(other)
    self.date <=> other.date
  end

  def contact_id=(newval)
    self.write_attribute(:contact_id, newval)
    self.contact = Contact.find_by_id(newval.to_i)
  end

  def contact_id_and_by_today
    # Unless the contact id is empty, or the event date is after today.
    !(contact_id.nil? || self.volunteer_shift.volunteer_event.date > Date.today)
  end

  def voltask_count
    self.contact_volunteer_task_type_count ? self.contact_volunteer_task_type_count.attributes["count"] : 0
  end

  before_validation :set_values_if_stuck
  def set_values_if_stuck
    return unless volshift_stuck
    volunteer_shift.set_values_if_stuck(self)
  end

  after_destroy { |record| if record.volunteer_shift && record.volunteer_shift.stuck_to_assignment; record.volunteer_shift.destroy; else VolunteerShift.find_by_id(record.volunteer_shift_id).fill_in_available; end}
  after_save {|record| if record.volunteer_shift && record.volunteer_shift.stuck_to_assignment; record.volunteer_shift.save; end}
  after_save { |record| VolunteerShift.find_by_id(record.volunteer_shift_id).fill_in_available }

  def volunteer_shift_attributes=(attrs)
    self.volunteer_shift.attributes=(attrs) # just pass it up
  end

  def if_builder_assigned
    self.contact_id and self.volunteer_shift.volunteer_task_type_id and self.volunteer_shift.volunteer_task_type.program.name == 'build'
  end

  def not_assigned
    contact_id.nil? and !closed
  end

  def volshift_stuck
    self.volunteer_shift && self.volunteer_shift.stuck_to_assignment
  end

  def time_shift(val)
    self.start_time += val
    self.end_time += val
  end

  def validate
    if self.contact_id && self.contact_id_changed? && self.volunteer_shift && self.volunteer_shift.roster && self.volunteer_shift.roster.contact_type
      errors.add("contact_id", "does not have the contact type required to sign up for a shift in this roster (#{self.volunteer_shift.roster.contact_type.description.humanize.downcase})") unless self.contact.contact_types.include?(self.volunteer_shift.roster.contact_type)
    end
    if self.volunteer_shift && self.volunteer_shift.stuck_to_assignment
      errors.add("contact_id", "is empty for an assignment-based shift") if self.contact_id.nil?
    end
    if self.closed
      errors.add("contact_id", "cannot be assigned to a closed shift") unless self.contact_id.nil?
    end
    unless self.cancelled?
      errors.add("contact_id", "is not an organization and is already scheduled during that time (#{self.find_overlappers(:for_contact).map{|x| "during " + x.time_range_s + " in " + x.slot_type_desc}.join(", ")})") if !(self.contact.nil?) and !(self.contact.is_organization) and self.find_overlappers(:for_contact).length > 0
      errors.add("volunteer_shift_id", "is already assigned during that time (#{self.find_overlappers(:for_slot).map{|x| "during " + x.time_range_s + " to " + x.contact_display}.join(", ")})") if self.volunteer_shift && !self.volunteer_shift.not_numbered && self.find_overlappers(:for_slot).length > 0
     end
    errors.add("end_time", "is before the start time") unless self.start_time < self.end_time
    if self.contact_id && self.contact_id_changed? && self.contact && (!self.cancelled?) && self.volunteer_shift && self.volunteer_shift.roster && self.volunteer_shift.roster.restrict_from_sked && self.volunteer_shift.roster.restrict_to_every_n_days && self.volunteer_shift.volunteer_event && self.volunteer_shift.volunteer_event.date >= (Date.today + self.volunteer_shift.roster.restrict_to_every_n_days)
      in_range = self.contact.assignments.not_cancelled.within_n_days_of(self.volunteer_shift.roster.restrict_to_every_n_days, self.volunteer_shift.volunteer_event.date).for_sked_id(self.volunteer_shift.roster.restrict_from_sked_id).select{|x| x.id != self.id}
      errors.add("contact_id", "is already scheduled in #{self.volunteer_shift.roster.restrict_from_sked.name} within #{self.volunteer_shift.roster.restrict_to_every_n_days} days: #{in_range.map{|x| "in " + x.slot_type_desc + " on " + x.volunteer_shift.volunteer_event.date.to_s}.join(", ")}") if in_range.length > 0
    end
  end

  def date
    volunteer_shift.date
  end

  named_scope :is_after_today, lambda {||
    { :conditions => ['(SELECT date FROM volunteer_events WHERE id = (SELECT volunteer_event_id FROM volunteer_shifts WHERE id = assignments.volunteer_shift_id)) > ?', Date.today] }
  }

  named_scope :on_or_after_today, lambda {||
    { :conditions => ['(SELECT date FROM volunteer_events WHERE id = (SELECT volunteer_event_id FROM volunteer_shifts WHERE id = assignments.volunteer_shift_id)) >= ?', Date.today] }
  }

  named_scope :not_yet_attended, :conditions => ['attendance_type_id IS NULL']

  def internal_date_hacks
    @internal_date_hack_value || self.volunteer_shift.volunteer_event.date
  end

  attr_writer :internal_date_hack_value

  named_scope :potential_overlappers, lambda{|assignment|
    tid = assignment.id
    tdate = assignment.internal_date_hacks
    { :conditions => ['(id != ? OR ? IS NULL) AND (attendance_type_id IS NULL OR attendance_type_id NOT IN (SELECT id FROM attendance_types WHERE cancelled = \'t\')) AND volunteer_shift_id IN (SELECT volunteer_shifts.id FROM volunteer_shifts JOIN volunteer_events ON volunteer_events.id = volunteer_shifts.volunteer_event_id WHERE volunteer_events.date = ?)', tid, tid, tdate] }
  }

  named_scope :not_cancelled, :conditions => ['(attendance_type_id IS NULL OR attendance_type_id NOT IN (SELECT id FROM attendance_types WHERE cancelled = \'t\'))']

  named_scope :for_contact, lambda{|assignment|
    tcid = assignment.contact.id
    { :conditions => ['contact_id = ?', tcid] }
  }

  named_scope :for_slot, lambda{|assignment|
    has_task_type = ! assignment.volunteer_shift.volunteer_task_type_id.nil?
    ret = nil
    if has_task_type
      rid = assignment.volunteer_shift.roster_id
      tslot = assignment.volunteer_shift.slot_number
      ttid = assignment.volunteer_shift.volunteer_task_type_id
      ret = {:conditions => ['contact_id IS NOT NULL AND volunteer_shift_id IN (SELECT id FROM volunteer_shifts WHERE slot_number = ? AND volunteer_task_type_id = ? AND roster_id = ?)', tslot, ttid, rid]}
    else
      rid = assignment.volunteer_shift.roster_id
      tslot = assignment.volunteer_shift.slot_number
      teid = assignment.volunteer_shift.volunteer_event_id
      ret = {:conditions => ['contact_id IS NOT NULL AND volunteer_shift_id IN (SELECT id FROM volunteer_shifts WHERE slot_number = ? AND volunteer_event_id = ? AND volunteer_task_type_id IS NULL AND roster_id = ?)', tslot, teid, rid]}
    end
    ret
  }

  def first_time_in_area?
    if self.contact and self.volunteer_shift and self.volunteer_shift.volunteer_task_type
      return !ContactVolunteerTaskTypeCount.has_volunteered?(self.contact_id, self.volunteer_shift.volunteer_task_type_id)
    else
      return false
    end #  and self.contact_id_changed? moved outside because we use update_attributes
  end

  def my_call_status
    self.call_status_type_id ? self.call_status_type.name : "not called yet"
  end

  def display_call_status
    " - " + self.my_call_status + " - "
  end

  def display_phone_numbers
    self.contact_id ? self.contact.display_phone_numbers : ""
  end

  def sandbox?
    self.volunteer_shift and self.volunteer_shift.roster and self.volunteer_shift.roster.sandbox?
  end

  def does_conflict?(other)
    return false if self.sandbox? or other.sandbox?
    arr = [self, other]
    arr = arr.sort_by(&:start_time)
    a, b = arr
    a.end_time > b.start_time
  end

  def find_overlappers(type)
    Assignment.potential_overlappers(self).send(type, self).select{|x| self.does_conflict?(x)}
  end

  def description
    self.volunteer_shift.volunteer_event.date.strftime("%D") + " " + self.time_range_s + " " + self.slot_type_desc
  end

  def slot_type_desc
    b = (self.volunteer_shift.volunteer_task_type_id.nil? ? self.volunteer_shift.volunteer_event.description : self.volunteer_shift.volunteer_task_type.description)
    b = b + " (#{self.volunteer_shift.description})" if self.volunteer_shift.description and self.volunteer_shift.description.length > 0
    b
   end

  def display_name
    ((!(self.volunteer_shift.description.nil? or self.volunteer_shift.description.blank?)) ? self.volunteer_shift.description + ": " : "") + self.contact_display
  end

  def cancelled?
    (self.attendance_type and self.attendance_type.cancelled)
  end

  def attended?
    (self.attendance_type and !self.attendance_type.cancelled)
  end

  def contact_display
    if self.closed
      return "(closed)"
    elsif contact_id.nil?
      return "(available)"
    else
      return self.contact.display_name + "(#{self.voltask_count})"
    end
  end

  def contact_id_and_today
    (!!contact_id) && (self.volunteer_shift.volunteer_event.date <= Date.today)
  end

  def time_range_s
    return "" unless start_time and end_time
    (start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def has_own_notes
    ((!self.notes.nil?) and self.notes.length > 0)
  end

  def has_notes
    (self.contact and (!self.contact.notes.nil?) and self.contact.notes.length > 0) or has_own_notes
  end

  def skedj_style(overlap, last)
    if self.cancelled?
      return 'cancelled'
    end
    if self.closed
      return 'cancelled'
    end
    if self.contact_id.nil?
      return 'available'
    end
    if overlap and !(last.cancelled? or self.cancelled?) and !self.volunteer_shift.not_numbered # TODO: FIXME: BUGGY? need a order by cancelled too then probably..
      return 'hardconflict'
    end
    if self.end_time > self.volunteer_shift.send(:read_attribute, :end_time) or self.start_time < self.volunteer_shift.send(:read_attribute, :start_time)
      return 'mediumconflict'
    end
    if self.attendance_type_id
      return 'checked_in'
    end
    return 'shift'
  end
end
