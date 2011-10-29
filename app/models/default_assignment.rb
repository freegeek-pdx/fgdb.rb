class DefaultAssignment < ActiveRecord::Base
  belongs_to :contact
  belongs_to :volunteer_default_shift
  validates_presence_of :set_weekday_id, :if => :volshift_stuck
  delegate :set_weekday_id, :set_weekday_id=, :to => :volunteer_default_shift
  delegate :effective_on, :effective_on=, :to => :volunteer_default_shift
  delegate :ineffective_on, :ineffective_on=, :to => :volunteer_default_shift
  before_validation :set_values_if_stuck

  def set_values_if_stuck
    return unless volshift_stuck
    volunteer_default_shift.set_values_if_stuck
  end

  def volshift_stuck
    self.volunteer_default_shift && self.volunteer_default_shift.stuck_to_assignment
  end

  after_destroy { |record| record.volunteer_default_shift.destroy if record.volunteer_default_shift && record.volunteer_default_shift.stuck_to_assignment}

  after_destroy { |record| if record.volunteer_default_shift && record.volunteer_default_shift.stuck_to_assignment; record.volunteer_default_shift.destroy; else VolunteerDefaultShift.find_by_id(record.volunteer_default_shift_id).fill_in_available(record.slot_number); end}
  after_save { |record| VolunteerDefaultShift.find_by_id(record.volunteer_default_shift_id).fill_in_available(record.slot_number) }
  after_save {|record| if record.volunteer_default_shift && record.volunteer_default_shift.stuck_to_assignment; record.volunteer_default_shift.save; end}

  validates_presence_of :volunteer_default_shift
  validates_associated :volunteer_default_shift

  def validate
    if self.volunteer_default_shift && self.volunteer_default_shift.stuck_to_assignment
      errors.add("contact_id", "is empty for a assignment-based shift") if self.contact_id.nil?
    end
    errors.add("contact_id", "is not an organization and is already scheduled during that time") if self.contact and !(self.contact.is_organization) and (self.find_overlappers(:for_contact).length > 0)
#    errors.add("volunteer_default_shift_id", "is already assigned during that time") if self.volunteer_default_shift && !self.volunteer_default_shift.not_numbered && self.find_overlappers(:for_slot).length > 0 # TODO maybe?
  end

  def does_conflict?(other)
    arr = [self, other]
    arr = arr.sort_by(&:start_time)
    a, b = arr
    a.end_time > b.start_time
  end

  def find_overlappers(type)
    self.class.potential_overlappers(self).send(type, self).select{|x| self.does_conflict?(x)}
  end

  named_scope :potential_overlappers, lambda{|assignment|
    tid = assignment.id
    tday = assignment.volunteer_default_shift.volunteer_default_event.weekday_id
    { :conditions => ['(id != ? OR ? IS NULL) AND volunteer_default_shift_id IN (SELECT volunteer_default_shifts.id FROM volunteer_default_shifts JOIN volunteer_default_events ON volunteer_default_events.id = volunteer_default_shifts.volunteer_default_event_id WHERE volunteer_default_events.weekday_id = ? AND (ineffective_on IS NULL AND effective_on IS NULL))', tid, tid, tday] } # FIXME: handle the ineffective_on logic
  }

  named_scope :for_contact, lambda{|assignment|
    tcid = assignment.contact.id
    { :conditions => ['contact_id = ?', tcid] }
  }

  def volunteer_default_shift_attributes=(attrs)
    self.volunteer_default_shift.attributes=(attrs) # just pass it up
  end

  attr_accessor :redirect_to
  def slot_type_desc
    (self.volunteer_default_shift.volunteer_task_type_id.nil? ? self.volunteer_default_shift.volunteer_default_event.description : self.volunteer_default_shift.volunteer_task_type.description)
   end

  def description
    self.volunteer_default_shift.volunteer_default_event.weekday.name + " " + self.time_range_s + " " + self.slot_type_desc
  end

  def skedj_style(overlap, last)
    if self.contact_id.nil?
      return 'available'
    end
    if overlap
      return 'hardconflict'
    end
    if self.end_time > self.volunteer_default_shift.send(:read_attribute, :end_time) or self.start_time < self.volunteer_default_shift.send(:read_attribute, :start_time)
      return 'mediumconflict'
    end
    return 'shift'
  end

  def left_method_name
    a = [self.volunteer_default_shift.volunteer_task_type_id.nil? ? self.volunteer_default_shift.volunteer_default_event.description : volunteer_default_shift.volunteer_task_type.description]
    a << self.volunteer_default_shift.description
    a << self.slot_number
    a.select{|x| x.to_s.length > 0}.join(", ")
  end

  def time_range_s
    (start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def display_name
   ((!(self.volunteer_default_shift.description.nil? or self.volunteer_default_shift.description.blank?)) ? self.volunteer_default_shift.description + ": " : "") + self.contact_display + ((self.volunteer_default_shift.effective_on.nil? and self.volunteer_default_shift.ineffective_on.nil?) ? "" : " (#{self.effective_on || "beginning of time"} till #{self.ineffective_on || "end of time"})")
  end

  def contact_display
    if contact_id.nil?
      return "(available)"
    else
      return self.contact.display_name
    end
  end
end

