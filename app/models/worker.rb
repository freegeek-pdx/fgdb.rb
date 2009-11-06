class Worker < ActiveRecord::Base
  has_many :standard_shifts
  has_and_belongs_to_many :jobs
  belongs_to :worker_type
  has_and_belongs_to_many :meetings
  has_many :work_shifts
  has_many :vacations
  belongs_to :contact
  validates_existence_of :contact, :allow_nil => false

  def is_available?( shift = Workshift.new )
    true
  end

  def effective_now?
    date = DateTime.now
    (effective_date.nil? || effective_date <= date) && (ineffective_date.nil? || ineffective_date > date)
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
end
