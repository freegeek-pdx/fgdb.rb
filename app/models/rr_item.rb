class RrItem < ActiveRecord::Base
  belongs_to :rr_set
  validates_presence_of :rr_set_id
  
  def occurs? (date = Date.today )
  end

  def name
    range = ''
    if min_day_of_month and max_day_of_month
      if min_day_of_month == max_day_of_month
        range = min_day_of_month.to_s
      else
        range = min_day_of_month.to_s + '-' + max_day_of_month.to_s 
      end
    elsif min_day_of_month
      range = min_day_of_month.to_s + ' on'
    elsif max_day_of_month
      range = 'until ' + max_day_of_month.to_s
    end
    month = ''
    if month_of_year_01 and month_of_year_02 and month_of_year_03 and month_of_year_04 and month_of_year_05 and month_of_year_06 and month_of_year_07 and month_of_year_08 and month_of_year_09 and month_of_year_10 and month_of_year_11 and month_of_year_12
      month = ''
    else
      if month_of_year_01
        month += 'Jan '
      end
      if month_of_year_02
        month += 'Feb '
      end
      if month_of_year_03
        month += 'Mar '
      end
      if month_of_year_04
        month += 'Apr '
      end
      if month_of_year_05
        month += 'May '
      end
      if month_of_year_06
        month += 'Jun '
      end
      if month_of_year_07
        month += 'Jul '
      end
      if month_of_year_08
        month += 'Aug '
      end
      if month_of_year_09
        month += 'Sep '
      end
      if month_of_year_10
        month += 'Oct '
      end
      if month_of_year_11
        month += 'Nov '
      end
      if month_of_year_12
        month += 'Dec '
      end
    end
    date_clause = ''
    if month == '' and range == ''
      date_clause = ''
    elsif month == ''
      date_clause = range
    elsif range == ''
      date_clause = month
    else
      date_clause = month + range
    end
    pre = ''
    if week_of_month_1 and week_of_month_2 and week_of_month_3 and week_of_month_4 and week_of_month_5
      pre = ''
    else
      if week_of_month_1
        pre += '1st '
      end
      if week_of_month_2
        pre += '2nd '
      end
      if week_of_month_3
        pre += '3rd '
      end
      if week_of_month_4
        pre += '4th '
      end
      if week_of_month_5
        pre += '5th '
      end
    end
    weekday = ''
    if weekday_0 and weekday_1 and weekday_2 and weekday_3 and weekday_4 and weekday_5 and weekday_6
      if pre == ''
        weekday = ''
      else
        weekday = 'any weekday'
      end
    else
      if weekday_0
        weekday += 'Sun '
      end
      if weekday_1
        weekday += 'Mon '
      end
      if weekday_2
        weekday += 'Tue '
      end
      if weekday_3
        weekday += 'Wed '
      end
      if weekday_4
        weekday += 'Thu '
      end
      if weekday_5
        weekday += 'Fri '
      end
      if weekday_6
        weekday += 'Sat '
      end
    end
    weekday_clause = pre + weekday

    if weekday_clause == '' and date_clause == ''
      ret = 'whenever'
    elsif weekday_clause == ''
      ret = date_clause
    elsif date_clause == ''
      ret = weekday_clause
    else
      ret = date_clause + ' and ' + weekday_clause
    end
    ret
  end
end
