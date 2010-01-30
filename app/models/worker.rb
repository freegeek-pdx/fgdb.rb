class Worker < ActiveRecord::Base
  has_many :standard_shifts
  has_and_belongs_to_many :jobs
  belongs_to :worker_type
  has_and_belongs_to_many :meetings
  has_many :work_shifts
  has_many :vacations
  belongs_to :contact
  validates_existence_of :contact, :allow_nil => false
  has_many :workers_worker_types
  validates_associated :workers_worker_types
  has_and_belongs_to_many :worker_types

  validate :worker_types_validated
  def worker_types_validated
    set_temp_worker_association
    raise if self.workers_worker_types.length == 0
    self.workers_worker_types.each{|x|
      raise x.errors.full_messages.to_s if ! x.valid?
    }
  end

  def set_temp_worker_association
    if ! @temp_worker_association.nil? and self.workers_worker_types.length == 0
      self.workers_worker_types = [@temp_worker_association]
      self.workers_worker_types.first.worker_id = self.id if self.id
    end
  end

  after_save :save_worker_types
  def save_worker_types
    set_temp_worker_association
    self.workers_worker_types.each{|x|
      x.save!
    }
  end

  def is_available?( shift = Workshift.new )
    true
  end

  def effective_now?
    date = DateTime.now
    (effective_date.nil? || effective_date <= date) && (ineffective_date.nil? || ineffective_date > date)
  end

  named_scope :effective_in_range, lambda { |*args|
    my_start = my_end = nil
    if args.length == 1 && args[0].is_a?(PayPeriod)
      my_start = args[0].start_date
      my_end = args[0].end_date
    elsif args.length == 1 && args[0].is_a?(Range)
      my_start = args[0].min
      my_end = args[0].max
    elsif args.length == 2 && args[0].is_a?(Date) && args[1].is_a?(Date)
      my_start = args[0]
      my_end = args[1]
    else
      raise ArgumentError
    end
    {:conditions => ['(effective_date IS NULL OR effective_date < ?) AND (ineffective_date IS NULL OR ineffective_date > ?)', my_end, my_start]}
  }

  named_scope :real_people, :conditions => {:virtual => false}

  def sort_by
    self.contact ? (self.contact.surname + ", " + self.contact.first_name) : self.id.to_s
  end

  def hours_worked_on_day_caching(cache, x)
    cache[x] ||= hours_worked_on_day(x)
  end

  def worker_type_on_day(date)
    c = self.workers_worker_types.effective_on(date).first
    c.nil? ? nil : c.worker_type
  end

  def worker_type_id
    worker_type.nil? ? nil : worker_type.id
  end

  def worker_type_id=(value)
    if ! worker_type_id.nil? && worker_type_id != value
      raise
    end
    t = WorkerType.find_by_id(value)
    self.workers_worker_types = [WorkersWorkerType.new(:worker => self, :worker_type => t)]
    @temp_worker = t
    @temp_worker_association = self.workers_worker_types.first
  end

  def worker_type # FIXME: remove this
    @temp_worker ? @temp_worker : worker_type_today
  end

  def worker_type_today
    self.worker_type_on_day(Date.today)
  end

  def primary_worker_type_in_range(start_d, end_d)
    h = {}
    (start_d..end_d).to_a.each{|x|
      t = worker_type_on_day(x)
      h[t] = (h[t] || 0) + 1
    }
    h = h.to_a
    h = h.sort_by{|x| x[1]}.delete_if{|x| x[0].name == "inactive"}
    h.first ? h.first.first : WorkerType.find_by_name("inactive")
  end

  def to_payroll_hash(pay_period)
    # further optimization: determine the weeks and holidays outside of the workers loop
    cache = {}
    h = {}
    h[:name] = self.sort_by
    h[:type] = self.primary_worker_type_in_range(pay_period.start_date, pay_period.end_date).name
    h[:hours] = (pay_period.start_date..pay_period.end_date).to_a.inject(0.0){|t, x| t+= self.hours_worked_on_day_caching(cache, x)}
    h[:holiday] = Holiday.find(:all, :conditions => ["holiday_date >= ? AND holiday_date <= ? AND is_all_day = 't'", pay_period.start_date, pay_period.end_date]).inject(0.0){|t,x| t+=self.holiday_credit_per_day}
    days = {}
    (pay_period.start_date..pay_period.end_date).to_a.each{|x| x = x.wday; days[x] ||= 0; days[x] += 1;}
    a = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    t = 0.0
    days.each{|k,v|
      t += (self.send(a[k.to_i]) * v)
    }
    minimum = t * self.floor_ratio
    h[:pto] = [0.0, minimum - (h[:hours] + h[:holiday])].max
    h[:overtime] = 0.0
    (pay_period.start_date..pay_period.end_date).to_a.select{|x| x.wday == 0}.each{|endit|
      startit = endit - 6
      holidays = Holiday.find(:all, :conditions => ["holiday_date >= ? AND holiday_date <= ? AND is_all_day = 't'", startit, endit]).inject(0.0){|t,x| t+=self.holiday_credit_per_day}
      logged = (startit..endit).to_a.inject(0.0){|t, x| t+= self.hours_worked_on_day_caching(cache, x)}
      total = holidays + logged
      h[:overtime] += [0.0, total - self.ceiling_hours].max
    }
    h[:hours] -= h[:overtime]
    return h
  end

  def shifts_for_day(date)
    logged = logged_shifts_for_day(date)
    return [true, logged].flatten if logged.length > 0
    return [false, scheduled_shifts_for_day(date)].flatten
  end

  def scheduled_shifts_for_day(date)
    shifts = WorkShift.find(:all, :conditions => ['shift_date = ? AND worker_id = ?', date, self.id])
    shifts = shifts.map{|x| x.to_worked_shift}.delete_if{|x| x == nil}
    return shifts
  end

  def logged_shifts_for_day(date)
    return WorkedShift.find(:all, :conditions => ['date_performed = ? AND worker_id = ?', date, self.id])
  end

  def hours_worked_on_day(date)
    logged_shifts_for_day(date).inject(0.0){|t,x| t += x.duration}
  end

  def hours_effective_on_day(date)
    amount = hours_worked_on_day(date)
    amount += holiday_credit_per_day if Holiday.is_holiday?(date)
    return amount
  end

  def fill_in_for_calendar(calendar)
    calendar.set_missing_dates{|x| v = self.hours_worked_on_day(x)}
  end

  def fill_in_maximum_for_calendar(calendar)
    calendar.set_missing_dates{|x| v = self.maximum_on_day(x)}
  end

  def hours_scheduled_for_weekday(date)
    self.send(date.strftime("%A").downcase.to_sym)
  end

  def maximum_on_day(day)
    self.send(day.strftime("%A").downcase.to_sym).to_f
  end

  def holiday_credit_per_day
    salaried ? (ceiling_hours / 5.0) : 0.0
  end

  def floor_ratio
    floor_hours / ceiling_hours
  end

  def total_hours
    (0..6).map{|x| Date.strptime(x.to_s, "%w").strftime("%A").downcase}.inject(0.0){|t,x| t += self.send(x.to_sym).to_f}
  end
end
