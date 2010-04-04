module WorkedShiftsHelper
  def url_for_log(worker, date, controller = nil)
    worker = worker.id if worker.class == Worker
    date = date.to_date if date.class == DateTime
    date = date.to_s if date.class == Date
    h = {:controller => "worked_shifts", :action => "edit", :worked_shift => {:worker_id => worker, :date_performed => date}}
    if controller
      return controller.url_for h
    else
      url_for h
    end
  end

  def get_hash(*a)
    date, worker, hours = a
    hashkeys = %w[total_today total_week max_week overtime expected_minimum total_pay_period pto normally_worked]
    hash = {}
    hashkeys.each{|x| hash[x.to_sym] = 0.0}
    if hours
      hash[:total_today] = hours
    end
    week = HoursCalendar.for_week_of(date)
    if hours
      week.set_date(date, hours)
      week.freeze_date(date)
    end
    week.fill_in_workers_hours(worker)
    week.add_in_holidays(worker)
    hash[:total_week] = week.total
    hash[:max_week] = worker.ceiling_hours
    hash[:overtime] = [0.0, week.total - worker.ceiling_hours].max
    pay_period = HoursCalendar.for_pay_period_of(date)
    max_date = nil
    if hours
      max_date = [Date.today, date].max
    else
      max_date = [Date.today, pay_period.end_date].min
    end
    expected_this_far = HoursCalendar.new(pay_period.start_date, max_date)
    expected_this_far.fill_in_workers_maximums(worker)
    minimum = expected_this_far.total * worker.floor_ratio
    hash[:expected_minimum] = minimum
    hash[:expected_maximum] = expected_this_far.total
    this_far = HoursCalendar.new(pay_period.start_date, max_date)
    if hours
      this_far.set_date(date, hours)
      this_far.freeze_date(date)
    end
    this_far.fill_in_workers_hours(worker)
    pay_period.load_from_calendar(this_far)
    pay_period.add_in_holidays(worker)
    hash[:pay_period] = pay_period
    hash[:total_pay_period] = pay_period.total
    hash[:pto] = [0.0, minimum - pay_period.total].max
    hash[:normally_worked] = worker.send(date.strftime("%A").downcase.to_sym)
    return hash
  end
end
