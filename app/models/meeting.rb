class Meeting < Shift
  has_many :standard_shifts
  has_many :work_shifts
  has_and_belongs_to_many :workers
  belongs_to :worker
  belongs_to :weekday
  belongs_to :schedule
  belongs_to :frequency_type
  belongs_to :coverage_type

  def name
    ret = meeting_name + ' ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end
end
