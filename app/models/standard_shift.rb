class StandardShift < Shift
  belongs_to :coverage_type
  belongs_to :job
  belongs_to :meeting
  belongs_to :schedule
  belongs_to :weekday
  belongs_to :worker
  has_many :work_shifts

  def name
    ret = Job.find(:first, :conditions => "id = #{job_id}").name + ' ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

  def long_name
    weekday = Weekday.find(:first, :conditions => "id = #{weekday_id}").short_name + ', ' 
    ret = weekday + Job.find(:first, :conditions => "id = #{job_id}").name + ' ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

  def job_name
    weekday = Weekday.find(:first, :conditions => "id = #{weekday_id}").short_name + ', ' 
    ret = weekday + Worker.find(:first, :conditions => "id = #{worker_id}").name + ' ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

end
