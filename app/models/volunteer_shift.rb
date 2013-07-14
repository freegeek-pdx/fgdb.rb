class VolunteerShift < ActiveRecord::Base
  validates_presence_of :roster_id
  validates_presence_of :end_time
  validates_presence_of :start_time

  belongs_to :volunteer_task_type
  has_many :assignments
  belongs_to :program
  belongs_to :roster

  belongs_to :volunteer_event

  has_many :contact_volunteer_task_type_counts, :primary_key => 'volunteer_task_type_id', :foreign_key => 'volunteer_task_type_id' #:through => :volunteer_task_type

  def validate
    errors.add("end_time", "is before the start time") unless self.start_time && self.end_time && self.start_time < self.end_time
  end

  def self.week_for_date(d)
    long_time_ago = Date.new(1901, 12, 22)
    difference = (d - long_time_ago).to_int
    ((difference / 7) % 2 ) == 0 ? "A" : "B"
  end

  def weeknum
    1 + ((self.date.day - 1) / 7)
  end

  def week
    VolunteerShift.week_for_date(self.date)
  end

  def slot_number=(a)
    write_attribute(:slot_number, a)
    self.not_numbered = (!slot_number)
  end

  def set_description
    self.description
  end

  def set_description=(desc)
    self.description=(desc)
  end

  def set_date_set
    @set_date_set
  end

  def set_date=(val)
    @set_date_set = true
    @set_date = val
  end

  def set_date
    @set_date_set ? @set_date : self.volunteer_event.date
  end

  def set_values_if_stuck(assn_in = nil)
    return unless self.stuck_to_assignment
    assn = assn_in || self.assignments.first
    return unless assn
    self.start_time = assn.start_time
    self.end_time = assn.end_time
    return unless self.volunteer_event_id.nil? or self.volunteer_event.description.match(/^Roster #/)
    return unless set_date_set
    roster = Roster.find_by_id(self.roster_id)
    if roster and !(set_date == nil || set_date == "")
      ve = roster.vol_event_for_date(set_date)
      ve.save! if ve.id.nil?
      self.volunteer_event = ve
      self.volunteer_event_id = ve.id
    else
      if self.volunteer_event.nil?
        self.volunteer_event = VolunteerEvent.new
      end
    end
  end

  def skedj_style(overlap, last)
    (overlap && !not_numbered) ? 'hardconflict' : 'shift'
  end

  def shift_display
    time_range_s + ((!(self.description.nil? or self.description.blank?)) ? (": " + self.description) : "")
  end

  def time_range_s
    return unless self.read_attribute(:start_time) and  self.read_attribute(:end_time)
    (self.my_start_time("%I:%M") + ' - ' + self.my_end_time("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def my_start_time(format = "%H:%M")
    read_attribute(:start_time).strftime(format)
  end

  def self._parse_time(time)
    Time.mktime(2000, 01, 01, *time.split(":").map(&:to_i))
  end

  def my_start_time=(str)
    write_attribute(:start_time, VolunteerShift._parse_time(str))
  end

  def my_end_time(format = "%H:%M")
    read_attribute(:end_time).strftime(format)
  end

  def my_end_time=(str)
    write_attribute(:end_time, VolunteerShift._parse_time(str))
  end

  def fill_in_available
    return if self.stuck_to_assignment
    Thread.current['volskedj_fillin_processing'] ||= []
    if Thread.current['volskedj_fillin_processing'].include?(self.id)
      return
    end
    begin
      Thread.current['volskedj_fillin_processing'].push(self.id)
      Assignment.find_all_by_volunteer_shift_id(self.id).select{|x| x.contact_id.nil? and !x.closed}.each{|x| x.destroy}
      inputs = [[(self.read_attribute(:start_time)), (self.read_attribute(:end_time))]]
      Assignment.find_all_by_volunteer_shift_id(self.id).select{|x| !x.cancelled?}.each{|x|
        inputs.push([(x.start_time), (x.end_time)])
      }
      results = self.class.range_math(*inputs)
      results.each{|x|
        a = Assignment.new
        a.volunteer_shift_id, a.start_time, a.end_time = self.id, x[0], x[1]
        a.volunteer_shift = self
        a.closed = self.volunteer_event.nowalkins
        a.save!
      }
    ensure
      Thread.current['volskedj_fillin_processing'].delete(self.id)
    end
  end

  after_save :fill_in_available

  def date
    self.volunteer_event.date
  end

  def date_display
    self.date.strftime('%A, %B %d, %Y').gsub( ' 0', ' ' )
  end

  def date_anchor
    self.date ? self.date.strftime('%Y%m%d') : ''
  end

  def time_shift(val)
    self.start_time += val
    self.end_time += val
  end

  def left_method_name
    [self.volunteer_task_type_id.nil? ? self.volunteer_event.description : self.volunteer_task_type.description, self.slot_number].select{|x| !x.nil?}.join(", ")
  end

  def left_unique_value
    left_method_name
  end

  def description_and_slot
    ((self.volunteer_task_type_id || -1) * 1000) + (self.not_numbered ? 0 : self.slot_number)
  end

  def weekday
    Weekday.find_by_id(self.date.strftime("%w"))
  end
end
