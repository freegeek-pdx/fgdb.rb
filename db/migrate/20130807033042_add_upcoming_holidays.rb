class AddUpcomingHolidays < ActiveRecord::Migration
  def self.up
    holidays = [["Independence Day", "2013-07-04"],
     ["Labor Day", "2013-08-31"],
     ["Thanksgiving Weekend", "2013-11-28"],
     ["Thanksgiving Weekend", "2013-11-29"],
     ["Thanksgiving Weekend", "2013-11-30"],
     ["Christmas Eve", "2013-12-24"],
     ["Christmas Day", "2013-12-25"],
     ["New Year's Eve", "2013-12-31"],
     ["New Year's Day", "2014-01-01"],
     ["International Worker's Day", "2014-05-01"],
     ["Memorial Day", "2014-05-24"],
     ["Independence Day", "2014-07-04"],
     ["Labor Day", "2014-08-30"],
     ["Thanksgiving Weekend", "2014-11-27"],
     ["Thanksgiving Weekend", "2014-11-28"],
     ["Thanksgiving Weekend", "2014-11-29"],
     ["Christmas Eve", "2014-12-24"],
     ["Christmas Day", "2014-12-25"],
     ["New Year's Eve", "2014-12-31"],
     ["New Year's Day", "2015-01-01"],
     ["International Worker's Day", "2015-05-01"],
     ["Memorial Day", "2015-05-23"],
     ["Independence Day", "2015-07-04"],
     ["Labor Day Saturday", "2015-09-05"],
     ["Thanksgiving Weekend", "2015-11-26"],
     ["Thanksgiving Weekend", "2015-11-27"],
     ["Thanksgiving Weekend", "2015-11-28"],
     ["Christmas Eve", "2015-12-24"],
     ["Christmas Day", "2015-12-25"],
     ["New Year's Eve", "2015-12-31"],
     ["New Year's Day", "2016-01-01"],
     ["International Worker's Day", "2016-04-30"],
     ["Memorial Day", "2016-05-28"],
     ["Independence Day", "2016-07-02"]]

    holidays.each do |n, d|
      d = Date.parse(d)
      Schedule.all.each do |s|
        h = Holiday.find_or_create_by_schedule_id_and_holiday_date(s.id, d.to_s)
        h.name = n
        h.is_all_day = true
        h.weekday_id = d.wday
        h.save!
      end
      puts n + ": " + d.to_s
    end
  end

  def self.down
  end
end
