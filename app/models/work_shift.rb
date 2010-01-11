class WorkShift < ActiveRecord::Base
  belongs_to :coverage_type
  belongs_to :job
  belongs_to :meeting
  belongs_to :schedule
  belongs_to :standard_shift
  belongs_to :weekday
  belongs_to :worker

  def name
    ret = Job.find(:first, :conditions => "id = #{job_id}").name + ' ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

  def weekday
    Weekday.find_by_id(self.weekday_id)
  end

  def weekday_id
    self.shift_date.wday
  end

  def to_worked_shift
    ws = WorkedShift.new({:worker_id => self.worker_id, :duration => ((self.end_time - self.start_time) / 3600).to_f, :date_performed => self.shift_date})
    if self.kind == "Meeting"
      ws.job_id = Job.find_by_name("Meeting").id
    elsif self.kind == "StandardShift"
      ws.job_id = self.job_id
    else # Unavailability
      return nil
    end
    return ws
  end

  def WorkShift::create_from_shift( shift = Shift.new, date = Date.new )

    #logger.info 'xxx: in create_from_shift'
    ret = WorkShift.new
    ret.actual = true
    ret.kind = shift.type
    ret.start_time = shift.start_time
    ret.end_time = shift.end_time
    ret.splitable = shift.splitable
    ret.mergeable = shift.mergeable
    ret.resizable = shift.resizable
    ret.meeting_name = shift.meeting_name
    ret.shift_date = date
    ret.effective_date = shift.effective_date
    ret.ineffective_date = shift.ineffective_date
    ret.all_day = shift.all_day
    ret.repeats_every = shift.repeats_every
    ret.repeats_on = shift.repeats_on
    ret.coverage_type_id = shift.coverage_type_id
    ret.frequency_type_id = shift.frequency_type_id
    ret.job_id = shift.job_id
    ret.meeting_id = shift.meeting_id
    ret.schedule_id = shift.schedule_id
    ret.weekday_id = shift.weekday_id
    ret.worker_id = shift.worker_id
    ret
  end

  def WorkShift::create_from_standard_shift( shift = StandardShift.new, date = Date.new )
    logger.info 'xxx: in create_from_standard_shift'
    ret = WorkShift.new
    ret.actual = true
    ret.kind = 'StandardShift'
    ret.shift_date = date
    ret.start_time = shift.start_time
    ret.end_time = shift.end_time
    ret.splitable = shift.splitable
    ret.mergeable = shift.mergeable
    ret.resizable = shift.resizable
    ret.worker_id = shift.worker_id
    #ret.coverage_type_id = shift.coverage_type_id
    ret.job_id = shift.job_id
    ret.schedule_id = shift.schedule_id
    #ret.standard_shift_id = shift.id
    ret.weekday_id = shift.weekday_id
    ret
  end

  def WorkShift::create_from_meeting( shift = Meeting.new, worker = Worker.new, date = Date.new )
    logger.info 'xxx: in create_from_meeting'
    ret = WorkShift.new
    ret.actual = true
    ret.kind = 'Meeting'
    ret.meeting_id = shift.id 
    ret.shift_date = date
    ret.start_time = shift.start_time
    ret.end_time = shift.end_time
    ret.effective_date = shift.effective_date
    ret.ineffective_date = shift.ineffective_date
    ret.splitable = shift.splitable
    ret.mergeable = shift.mergeable
    ret.resizable = shift.resizable
    ret.worker_id = worker.id
    #ret.coverage_type_id = shift.coverage_type_id
    ret.schedule_id = shift.schedule_id
    ret.weekday_id = shift.weekday_id
    ret.meeting_name = shift.meeting_name
    ret
  end

  def WorkShift::create_from_unavailability( shift = Unavailability.new, date = Date.new )
    logger.info 'xxx: in create_from_unavailability'
    ret = WorkShift.new
    ret.actual = true
    ret.kind = 'Unavailability'
    ret.shift_date = date
    ret.start_time = shift.start_time
    ret.end_time = shift.end_time
    ret.worker_id = shift.worker_id
    #ret.coverage_type_id = shift.coverage_type_id
    ret.weekday_id = shift.weekday_id
    ret
  end
end
