class ResourcesVolunteerEvent < ActiveRecord::Base
  belongs_to :resource
  belongs_to :volunteer_event
  belongs_to :resources_volunteer_default_event

  def skedj_style(overlap, last)
    overlap ? 'hardconflict' : 'shift'
  end

  def date_anchor
    self.date.strftime('%Y%m%d')
  end

  def date
    self.volunteer_event.date
  end

  def date_display
    self.date.strftime('%A, %B %d, %Y').gsub( ' 0', ' ' )
  end

  def weekday
    Weekday.find_by_id(self.date.strftime("%w"))
  end

  def time_shift(val)
    self.start_time += val
    self.end_time += val
  end

  def time_range_s
    (self.my_start_time("%I:%M") + ' - ' + self.my_end_time("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def my_start_time(format = "%H:%M")
    read_attribute(:start_time).strftime(format)
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

  def display
    time_range_s + ": " + self.volunteer_event.to_s
  end
end

