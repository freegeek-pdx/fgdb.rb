class WorkShift < ActiveRecord::Base
  acts_as_userstamp

  belongs_to :job
  belongs_to :meeting
  belongs_to :schedule
  belongs_to :standard_shift
  belongs_to :weekday
  belongs_to :worker

  def validate
    errors.add("end_time", "is before the start time") unless self.start_time && self.end_time && self.start_time < self.end_time
    errors.add("end_time", "is after 8PM") unless self.end_time && Time.parse(self.end_time.hour.to_s + ":" + self.end_time.min.to_s) <= Time.parse("20:00")
    errors.add("start_time", "is before 8AM") unless self.start_time && Time.parse(self.start_time.hour.to_s + ":" + self.start_time.min.to_s) >= Time.parse("8:00")
  end

  before_save :set_weekday_id

  before_save :set_standard_shift_if_none
  def set_standard_shift_if_none
    self.kind ||= 'StandardShift'
  end

  def shift_date_display
    self.shift_date.strftime('%A, %B %d, %Y').gsub( ' 0', ' ' )
  end

  def display_name_skedj
    skedj = Thread.current['skedj_obj']
    raise if skedj.nil?
    prepend = ""
    if skedj.opts[:presentation_mode] == "Edit"
      prepend = "[#{self.id}] "
    end
    prepend + display_name
  end

  def display_worker_skedj
    skedj = Thread.current['skedj_obj']
    raise if skedj.nil?
    prepend = ""
    if skedj.opts[:presentation_mode] == "Edit"
      prepend = "[#{self.id}] "
    end
    prepend + self.worker.name
  end

  def on_vacation
    if ["Meeting", "Unavailability"].include?(self.kind)
      self.destroy
    else
      self.worker = Worker.zero
      self.save!
    end
  end

  def display_name
    if self.kind == "Meeting"
      return self.meeting_name
    elsif self.kind == "Unavailability"
      return '(unavailable)'
    else
      return self.name
    end
  end

  def skedj_style(overlap, last)
    shift_style = ""
    if self.kind == 'Meeting'
      shift_style = 'meeting'
    elsif self.kind == 'Unavailability'
      shift_style = overlap ? 'hardconflict' : 'unavailable'
    elsif self.worker_id == 0
      shift_style = 'unfilled'
    elsif overlap
      shift_style = 'hardconflict'
    else
      shift_style = self.proposed ? 'proposed' : self.training ? 'training' : 'shift'
    end
    return shift_style
  end


  def set_weekday_id
    self.weekday_id = self.shift_date.wday
  end

  def time_range_s
    (start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")).gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' ).gsub(/^0/, "")
  end

  def name
    name_part + ' ' + time_range_s
  end

  def name_part
    (self.job ? job.name: '(no job)') + (offsite ? ' (Offsite)' : '') + (training ? ' (Training)' : '')
  end

  def to_worked_shift
    ws = WorkedShift.new({:offsite => self.offsite, :worker_id => self.worker_id, :duration => ((self.end_time - self.start_time) / 3600).to_f, :date_performed => self.shift_date})
    msgs = []
    if self.kind == "Meeting"
      if self.job
        ws.job_id = self.job_id
        msgs << "The \"#{self.meeting_name}\" meeting was recorded as a \"#{self.job.name}\" shift."
      else
        ws.job_id = Job.find_by_name("Meeting").id
      end
    elsif self.kind == "StandardShift"
      ws.job_id = self.job_id
      if ws.job.reason_cannot_log_hours and ws.job.reason_cannot_log_hours.length > 0
        return [nil, "A \"#{ws.job.name}\" shift lasting #{ws.duration} hours could not be added using that job: #{ws.job.reason_cannot_log_hours}"]
      end
    else # Unavailability
      return [nil, msgs]
    end
    return [ws, msgs]
  end

  def WorkShift::create_from_shift( shift = Shift.new, date = Date.new )

    #logger.info 'xxx: in create_from_shift'
    ret = WorkShift.new
    ret.actual = true
    ret.kind = shift.type
    ret.start_time = shift.start_time
    ret.end_time = shift.end_time
    ret.meeting_name = shift.meeting_name
    ret.shift_date = date
    ret.effective_date = shift.effective_date
    ret.ineffective_date = shift.ineffective_date
    ret.all_day = shift.all_day
    ret.repeats_every = shift.repeats_every
    ret.repeats_on = shift.repeats_on
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
    ret.worker_id = shift.worker_id
    ret.training = shift.training
    ret.offsite = shift.offsite
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
    ret.worker_id = worker.id
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
    ret.weekday_id = shift.weekday_id
    ret
  end
end
