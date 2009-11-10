module CalendarHelper
  def html_calendar(range, values)
    end_date = range.max
    start_date = range.min
    hash = values
    cal_start_date = start_date.dup
    cal_end_date = end_date.dup
    cal_start_date -= 1 while cal_start_date.wday != 0 # Sunday
    cal_end_date += 1 while cal_end_date.wday != 6 # Saturday
    cal_current_date = cal_start_date
    weeks = (((cal_end_date - cal_start_date).to_i + 1) / 7)
    table = HtmlTag.new("table", {:width => "98%", :border => 1, :style => "border-collapse: collapse;"})
    table.children << HtmlTag.new("tr", {}, (0..6).map{|x| Date.strptime(x.to_s, "%w").strftime("%a")}.map{|x| HtmlTag.new("th", {:colspan => 2}, [], x)})
    first = true
    weeks.times{
      tr = HtmlTag.new("tr")
      7.times {
        show_month = (first == true || cal_current_date.day == 1)
        first = false
        month_str = ""
        month_str = "[#{cal_current_date.strftime("%b")}] " if show_month
        tr.children << HtmlTag.new("td", {:align => "center", :width => "4%"}, [HtmlTag.new("small", {}, [], month_str + cal_current_date.day.to_s)])
        tr.children << HtmlTag.new("td", {:align => "right", :width => "10%"}, [HtmlTag.new("b", {}, [], values[cal_current_date])])
        cal_current_date += 1
      }
      table.children << tr
    }
    cal_current_date -= 1 # it got ++ed without being processed
    raise if cal_current_date != cal_end_date # math error
    return table.to_s
  end
end
