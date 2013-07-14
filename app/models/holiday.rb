class Holiday < ActiveRecord::Base
  belongs_to :weekday
  belongs_to :schedule
  validates_presence_of :start_time, :unless => :is_all_day
  validates_presence_of :end_time, :unless => :is_all_day
  validates_presence_of :holiday_date

  def Holiday.is_holiday?(day)
    !! Holiday.find(:first, :conditions => ["holiday_date = ? AND is_all_day = 't'", day])
  end

  def Holiday.add_credit_for_holidays_to_calendar(calendar,worker)
    calendar.add_for_day{|x| Holiday.is_holiday?(x) ? worker.holiday_credit_per_day(x) : 0}
  end
end
