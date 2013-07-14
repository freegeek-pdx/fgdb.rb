class DefaultAssignment < ActiveRecord::Base
  belongs_to :contact
  belongs_to :volunteer_default_shift
  validates_presence_of :set_weekday_id, :if => :volshift_stuck
  delegate :set_weekday_id, :set_weekday_id=, :to => :volunteer_default_shift
  delegate :effective_on, :effective_on=, :to => :volunteer_default_shift
  delegate :ineffective_on, :ineffective_on=, :to => :volunteer_default_shift
  before_validation :set_values_if_stuck
  delegate :set_description, :set_description=, :to => :volunteer_default_shift
  validates_existence_of :contact, :allow_nil => true

  def real_programs
    return [] unless self.volunteer_default_shift && self.volunteer_default_shift.roster
    return [] unless self.volunteer_default_shift.roster.limit_shift_signup_by_program
    return self.volunteer_default_shift.roster.skeds.select{|x| x.category_type == "Program"}.map{|x| x.name}
  end

  def contact_id=(newval)
    self.write_attribute(:contact_id, newval)
    self.contact = Contact.find_by_id(newval.to_i)
  end

  def next_cycle_date
    if self.week.to_s.strip.length == 0
      return ""
    end
    d = Date.today
    d += 1 while d.wday != self.set_weekday_id
    return ((VolunteerShift.week_for_date(d).upcase == self.week.upcase) ? d : (d + 7)).to_s
  end

  def next_cycle_date=(d)
    self.week = d.to_s.strip.length == 0 ? "" : VolunteerShift.week_for_date(Date.parse(d)).upcase
  end

  def set_values_if_stuck
    return unless volshift_stuck
    volunteer_default_shift.set_values_if_stuck(self)
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

  def not_assigned
    contact_id.nil? and !closed
  end

  named_scope :assigned, :conditions => ['contact_id IS NOT NULL']

  named_scope :for_slot, lambda{|assignment|
    slot = assignment.slot_number
    shift_id = assignment.volunteer_default_shift_id || assignment.volunteer_default_shift.id
    week = assignment.week.to_s.strip
    if week.length > 0
      ret = {:conditions => ["contact_id IS NOT NULL AND slot_number = ? AND volunteer_default_shift_id = ? AND (week IS NULL OR week IN ('', ' ', ?))", slot, shift_id, week]}
    else
      ret = {:conditions => ["contact_id IS NOT NULL AND slot_number = ? AND volunteer_default_shift_id = ?", slot, shift_id]}
    end
    ret
  }

  def validate
    if self.contact_id && self.contact_id_changed? && self.volunteer_default_shift && self.volunteer_default_shift.roster && self.volunteer_default_shift.roster.contact_type
      errors.add("contact_id", "does not have the contact type required to sign up for a shift in this roster (#{self.volunteer_default_shift.roster.contact_type.description.humanize.downcase})") unless self.contact.contact_types.include?(self.volunteer_default_shift.roster.contact_type)
    end
    if self.closed
      errors.add("contact_id", "cannot be assigned to a closed shift") unless self.contact_id.nil?
    end
    if self.volunteer_default_shift && self.volunteer_default_shift.stuck_to_assignment
      errors.add("contact_id", "is empty for an assignment-based shift") if self.contact_id.nil?
    end
    errors.add("contact_id", "is not an organization and is already scheduled during that time (#{self.find_overlappers(:for_contact).map{|x| "during " + x.time_range_s + " in " + x.slot_type_desc}.join(", ")})") if self.contact and !(self.contact.is_organization) and (self.find_overlappers(:for_contact).length > 0)
    errors.add("volunteer_default_shift_id", "is already assigned during that time (#{self.find_overlappers(:for_slot).map{|x| "during " + x.time_range_s + " to " + x.contact_display}.join(", ")})") if self.volunteer_default_shift && !(self.volunteer_default_shift.not_numbered) && self.find_overlappers(:for_slot).length > 0
  end

  def does_conflict?(other)
    return false if self.week.to_s.strip.length > 0 and other.week.to_s.strip.length > 0 and self.week.downcase != other.week.downcase
    return false if (self.weeks_enabled & other.weeks_enabled).length == 0
    arr = [self, other]
    arr = arr.sort_by(&:start_time)
    a, b = arr
    a.end_time > b.start_time
  end

  def find_overlappers(type)
    self.class.potential_overlappers(self).send(type, self).overlaps_effective(self).select{|x| self.does_conflict?(x)}
  end

  named_scope :overlaps_effective, lambda {|assignment|
    cond = ""
    opts = []
    if assignment.ineffective_on.nil? and assignment.effective_on.nil?
      cond = "1 = 1"
    else
      if !(assignment.ineffective_on.nil? or assignment.effective_on.nil?)
        cond = "((ineffective_on IS NULL OR ineffective_on > ?) AND (effective_on < ? OR effective_on IS NULL))"
        opts = [assignment.effective_on, assignment.ineffective_on]
      end
      if assignment.ineffective_on.nil?
        cond = "(ineffective_on IS NULL OR ineffective_on > ?)"
        opts = [assignment.effective_on]
      end
      if assignment.effective_on.nil?
        cond = "(effective_on < ? OR effective_on IS NULL)"
        opts = [assignment.ineffective_on]
      end
    end
    opts.unshift("volunteer_default_shift_id IN (SELECT volunteer_default_shifts.id FROM volunteer_default_shifts WHERE #{cond})")
    {:conditions => opts}
  }

  named_scope :potential_overlappers, lambda{|assignment|
    tid = assignment.id
    tday = assignment.volunteer_default_shift.volunteer_default_event.weekday_id
    { :conditions => ['(id != ? OR ? IS NULL) AND volunteer_default_shift_id IN (SELECT volunteer_default_shifts.id FROM volunteer_default_shifts JOIN volunteer_default_events ON volunteer_default_events.id = volunteer_default_shifts.volunteer_default_event_id WHERE volunteer_default_events.weekday_id = ?)', tid, tid, tday] }
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
    self.volunteer_default_shift.volunteer_default_event.weekday.name + " " + self.time_range_s + self.slot_type_desc
  end

  def skedj_style(overlap, last)
    if self.closed
      return 'cancelled'
    end
    if self.contact_id.nil?
      return 'available'
    end
    if overlap and !self.volshift_stuck and self.week.to_s.strip.length == 0 and self.weeks_enabled.length == 5 # FIXME
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

  def weeks_enabled
    [1, 2, 3, 4, 5].select{|n| self.send("week_#{n}_of_month")}
  end

  def time_range_s
    list = weeks_enabled
    (start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "") + (list.length == 5 ? "" : " [weeks: #{list.join(", ")}]") + (self.week.to_s.strip.length > 0 ? " (week " + self.week + ")" : "")
  end

  def display_name
   ((!(self.volunteer_default_shift.description.nil? or self.volunteer_default_shift.description.blank?)) ? self.volunteer_default_shift.description + ": " : "") + self.contact_display + ((self.volunteer_default_shift.effective_on.nil? and self.volunteer_default_shift.ineffective_on.nil?) ? "" : " (#{self.effective_on || "beginning of time"} till #{self.ineffective_on || "end of time"})")
  end

  def contact_display
    if self.closed
      return "(closed)"
    elsif contact_id.nil?
      return "(available)"
    else
      return self.contact.display_name
    end
  end
end

