class HoursCalendar
  def initialize(start_date, end_date)
    start_date = _purify_date(start_date)
    end_date = _purify_date(end_date)
    @start_date = start_date
    @end_date = end_date
    @dates = {}
    range.to_a.each{|x|
      @dates[x] = nil
    }
    @frozen = []
    @ignore_frozen = false
  end

  include CalendarHelper

  def to_html
    html_calendar(self.range, self.values)
  end

  def start_date
    @start_date
  end

  def end_date
    @end_date
  end

  def set_date(date, value)
    date = _purify_date(date)
    value = _purify_value(value)
    _in_range_or_die(date)
    _melted_or_die(date)
    @dates[date] = value
  end

  def get_date(date)
    date = _purify_date(date)
    _in_range_or_die(date)
    @dates[date] || 0.0
  end

  def freeze_date(date)
    date = _purify_date(date)
    _in_range_or_die(date)
    _is_set_or_die(date)
    @frozen << date unless @frozen.include?(date)
    true
  end

  def add_for_day
    @ignore_frozen = true
    begin
      range.to_a.each{|x|
        set_date(x, get_date(x) + yield(x))
      }
    ensure
      @ignore_frozen = false
    end
    true
  end

  def fill_in_workers_hours(worker)
    worker.fill_in_for_calendar(self)
  end

  def fill_in_workers_maximums(worker)
    worker.fill_in_maximum_for_calendar(self)
  end

  def add_in_holidays(worker)
    Holiday.add_credit_for_holidays_to_calendar(self, worker.holiday_credit_per_day)
  end

  def total
    @dates.values.select{|x| !x.nil?}.inject(0.0) {|t,x| t += x}
  end

  def is_set?(date)
    date = _purify_date(date)
    _in_range_or_die(date)
    ! @dates[date].nil?
  end

  def set_missing_dates
    range.to_a.each{|x|
      if !is_set?(x)
        set_date(x, yield(x))
      end
    }
    true
  end

  def melt_date(date)
    date = _purify_date(date)
    _in_range_or_die(date)
    !! @frozen.delete(date)
  end

  def is_frozen?(date)
    date = _purify_date(date)
    _in_range_or_die(date)
    return false if @ignore_frozen
    @frozen.include?(date)
  end

  def HoursCalendar.for_week_of(date)
    date = _purify_date(date)
    first_date = date.dup
    last_date = date.dup
    first_date -= 1 while first_date.wday != 1 # Monday
    last_date += 1 while last_date.wday != 0 # Sunday
    HoursCalendar.new(first_date, last_date)
  end

  def HoursCalendar.for_pay_period_of(date)
    date = _purify_date(date)
    p = PayPeriod.find_for_date(date)
    return nil if ! p
    HoursCalendar.new(p.start_date, p.end_date)
  end

  def load_from_calendar(calendar)
    common_range = (self.range.to_a & calendar.range.to_a)
    common_range.each{|x|
      set_date(x, calendar.get_date(x)) unless is_frozen?(x)
      freeze_date(x) if calendar.is_frozen?(x) # TODO: should this happen?
    }
  end

  def range
    @start_date..@end_date
  end

  def values
    @dates
  end

  private

  def _in_range_or_die(date)
    raise ArgumentError unless range.include?(date)
  end

  def _melted_or_die(date)
    raise TypeError if is_frozen?(date)
  end

  def _is_set_or_die(date)
    raise ArgumentError unless is_set?(date)
  end

  def _purify_date(date)
    HoursCalendar._purify_date(date)
  end

  def _purify_value(number)
    HoursCalendar._purify_value(number)
  end

  def HoursCalendar._purify_date(date)
    return Date.parse(date.to_s)
  end

  def HoursCalendar._purify_value(number)
    return number.to_f
  end
end
