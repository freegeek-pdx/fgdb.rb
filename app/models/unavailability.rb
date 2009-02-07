class Unavailability < Shift
  belongs_to :schedule
  belongs_to :weekday
  belongs_to :worker

  def name
    ret = '(unavailable) ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

  def long_name
    weekday = Weekday.find(:first, :conditions => "id = #{weekday_id}").short_name + ', ' 
    ret = weekday + '(unavailable) ' + start_time.strftime("%I:%M") + ' - ' + end_time.strftime("%I:%M")
    ret.gsub( ':00', '' ).gsub( ' 0', ' ').gsub( ' - ', '-' )
  end

  def which_week( date = Date.today.to_date )
    if self.repeats_every > 1
      long_time_ago = Date.new(1901, 12, 22)
      difference = (date - long_time_ago).to_int
      ((difference / 7) % self.repeats_every )
    else
      0
    end
  end

end
