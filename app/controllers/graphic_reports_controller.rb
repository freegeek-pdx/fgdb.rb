# TODO: reimplement Date class...we are converting between like 20
# different formats, and it's a PITA. tho, now that I have it all
# done, this todo will probably sit here for a few years...
# make it so that you have methods like .add_month and such
# cause there's a LOT of mess to do that kind of stuff
# it could also help clean up getting the second date range and the
# number between them, which are messy right now.

class GraphicReportsController < ApplicationController
  layout :with_sidebar

  def get_temp_file
    file = File.join(RAILS_ROOT, "tmp", "tmp", params[:id].sub("$", "."))
    respond_to do |format|
      format.jpeg { render :text => File.read(file) }
    end
    File.unlink(file)
  end

  def view
    generate_report_data
  end

  def index
    @report_types = report_types
  end

  def index2
    @valid_conditions = []
    @breakdown_types = breakdown_types
    case params[:conditions][:report_type]
    when "Average Frontdesk Income"
    when "Income"
    when "Active Volunteers"
      @breakdown_types = line_breakdown_types
    when "Sales Total"
    when "Donations Count"
    when "Volunteer Hours by Program"
      @breakdown_types = breakdown_types - ["Hour"]
    when "Donations gizmo count by type"
      @valid_conditions = ["gizmo_category_id", "gizmo_type_id"]
    when "Sales gizmo count by type"
      @valid_conditions = ["gizmo_category_id", "gizmo_type_id"]
    when "Sales amount by gizmo type"
      @valid_conditions = ["gizmo_category_id", "gizmo_type_id"]
    else
      raise NoMethodError
    end
  end

  private

  #########################
  # Time range type stuff #
  #########################

  # list of breakdown types:

  # line breakdown types are when the whole date range is chunked up
  # based on something
  def line_breakdown_types
    ["Yearly", "Quarterly", "Monthly", "Weekly", "Daily"]
  end

  # bar breakdown types are when you want to compare things like
  # "which day of the week has the highest average" and such
  def bar_breakdown_types
    ["Day of week", "Hour"]
  end

  # convert a date object into the string that should be put on the x
  # axis
  def x_axis_for(date)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      "Week of " + date.to_s
    when "Quarterly"
      string = date.strftime("%Y-Q")
      temp = date.strftime("%m").to_i
      hash = {:t1 => [1,2,3], :t2 => [4,5,6], :t3 => [7,8,9], :t4 => [10,11,12]}
      hash.each{|k,v|
        string += k.to_s.sub(/t/, "") if v.include?(temp)
      }
      string
    when "Daily"
      date.to_s
    when "Yearly"
      date.year.to_s
    when "Monthly"
      date.strftime("%b %y")
    when "Day of week"
      Date.strptime(date.to_s, "%w").strftime("%A")
    when "Hour"
      DateTime.strptime(date.to_s, "%H").strftime("%I:00 %p")
    else
      raise NoMethodError
    end
  end

  ###################
  # only if is_line #
  ###################

  # should return the total number of things that should be on the x
  # axis, minus one (this makes logical sense for simplicity)
  def number_between_them(end_date)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      (end_date - @start_date).to_i / 7
    when "Quarterly"
      # EWWWW. this whole number_between_them needs to be
      # eliminated. just do a "do {} while {current_date <=
      # backed_up(end_date)}" or somethin like that instead of
      # "number_between_them(blah).times{}".
      num = 0
      curdate = @start_date
      until curdate == end_date
        curdate = Date.parse(increase_arr(curdate.to_s.split("-").map{|x| x.to_i}).join("-"))
        num += 1
      end
      return num
    when "Daily"
      (end_date - @start_date).to_i
    when "Yearly"
      end_date.year - @start_date.year
    when "Monthly"
      ((end_date.year * 12) + end_date.month) - ((@start_date.year * 12) + @start_date.month)
    else
      raise NoMethodError
    end
  end

  # returns true if this is a "good" date (ie, the beginning of the
  # week), or if it needs to be backed up further
  # NOTE: should be called is_first_thing? to make sense in this
  # context
  # this is pretty stupid, as it will require a lot of iterations for
  # nothing. but it works.
  def is_last_thing?(date)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      date.strftime("%a") == "Mon"
    when "Quarterly"
      a = date.to_s.split("-")
      return [1,4,7,10].include?(a[1].to_i) && a[2] == "01"
    when "Daily"
      true
    when "Yearly"
      date.day == 1 && date.month == 1
    when "Monthly"
      date.day == 1
    else
      raise NoMethodError
    end
  end

  # get the date object for number "breakdowns" after the start date
  # return nil if you want that breakdown to be ignored (for example,
  # ignoring weekends on daily breakdown)
  def get_this_one(number)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      @start_date + (7*number)
    when "Quarterly"
      d = @start_date.to_s.split("-").map{|x| x.to_i}
      number.times{|x|
        d = increase_arr(d)
      }
      Date.parse(d.map{|x| x.to_s}.join("-"))
    when "Daily w/weekends" # NOT ACTUALLY used.
      @start_date + number
    when "Daily"
      date = @start_date + number
      if [0,1].include?(date.wday) # MEEP. the hard coded sunday and monday are *HORRIBLE*
        return nil
      else
        return date
      end
    when "Yearly"
      Date.parse((@start_date.year + number).to_s + "-01-01")
    when "Monthly"
      month = @start_date.month
      year = @start_date.year
      month += number
      while month > 12
        year += 1
        month -= 12
      end
      Date.parse("#{year}-#{month}-01")
    else
      raise NoMethodError
    end
  end

  # takes in what x_axis_for outputted, and the date object of the
  # start date, and reformats it for the graph (as a number that will
  # be used to place it somewhere on the x axis)
  def graph_x_axis_for(x_axis, date)
    case params[:conditions][:breakdown_type]
    when "Quarterly"
      x_axis.match(/-Q(.)/)
      x_axis.sub(/-Q.$/, "." + (($1.to_i - 1) * 25).to_s)
    when "Weekly"
      date = Date.parse(x_axis.sub(/Week of /, ""))
      other_thing = (date.cweek / 52.0)
      if other_thing >= 1.0
        other_thing = 0.999
      end
      date.cwyear.to_s + "." + other_thing.to_s.gsub(/0\./, "")
    when "Daily"
      date.year + (date.yday / 365.0)
    when "Yearly"
      x_axis
    when "Monthly"
      (date.year * 12) + date.month
    else
      raise NoMethodError
    end
  end

  # get the last day in the range
  def second_timerange(first)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      first + 6
    when "Quarterly"
      Date.parse(increase_arr(first.to_s.split("-").map{|x| x.to_i}).join("-")) - 1
    when "Daily"
      first
    when "Yearly"
      Date.parse(first.year.to_s + "-12-31")
    when "Monthly"
      month = first.month
      year = first.year
      month += 1
      if month > 12
        year += 1
        month -= 12
      end
      Date.parse("#{year}-#{month}-01") - 1
    else
      raise NoMethodError
    end
  end

  ##################
  # only if is_bar #
  ##################

  def extract_name_for_breakdown_type
    case params[:conditions][:breakdown_type]
    when "Day of week"
      return "DOW"
    when "Hour"
      return "hour"
    else
      raise NoMethodError
    end
  end

  def get_bar_list
    case params[:conditions][:breakdown_type]
    when "Day of week"
      v = 0..6
    when "Hour"
      v = 0..23
    else
      raise NoMethodError
    end
    return v.to_a
  end

  def check_date_for_extract_type(args, date)
    case args[:extract_type]
    when "DOW"
      return true if args[:extract_value] == date.cwday
    when "hour"
      return true
    else
      raise NoMethodError
    end
    return false
  end

  #####################
  # Report type stuff #
  #####################

  # list of report types
  def report_types
    ["Average Frontdesk Income", "Income", "Active Volunteers", "Sales Total", "Donations Count", "Volunteer Hours by Program", "Donations gizmo count by type", "Sales gizmo count by type", "Sales amount by gizmo type"]
  end

  # returns the title for that report type
  def get_title
    case params[:conditions][:report_type]
    when "Income"
      "Income report"
    when "Average Frontdesk Income"
      "Report of Average Income at Front Desk"
    when "Active Volunteers"
      "Report of Number of Active Volunteers"
    when "Sales Total"
      "Report of total sales in dollars"
    when "Donations Count"
      "Report of number of donations"
    when "Volunteer Hours by Program"
      "Report of volunteer hours by program"
    when "Donations gizmo count by type"
      "Count of gizmos donated by type"
    when "Sales gizmo count by type"
      "Count of gizmos sold by type"
    when "Sales amount by gizmo type"
      "Sales amount by gizmo type"
    else
      raise NoMethodError
    end
  end

  # calls a method specific to that report that takes args, explained
  # below, and returns a hash (one element for each line) with the key
  # being the name of the line and the value the number to be plotted
  # for that date range

  # anywhere in this file where you see a variable called args, it is a hash with these options:
  # :start_date - the first date to include
  # :end_date - the second date to inlcude
  # :extract_type - if also limiting by day of week, hour, etc, this will be not nil, so extract this and make sure it's equal to :extract_value
  # :extract_value - the value to make sure that the thing extracted from the date matches
  # :number_of_days - the numbef of days matching these criteria (for averaging, etc)
  def get_thing_for_timerange(args)
    case params[:conditions][:report_type]
    when "Income"
      get_income_for_timerange(args)
    when "Average Frontdesk Income"
      get_average_frontdesk(args)
    when "Active Volunteers"
      get_active_volunteers(args)
    when "Donations Count"
      get_donations_count(args)
    when "Sales Total"
      get_sales_money(args)
    when "Volunteer Hours by Program"
      get_volunteer_hours_by_program(args)
    when "Donations gizmo count by type"
     get_donation_count_by_gizmo(args)
    when "Sales gizmo count by type"
     get_sales_count_by_gizmo(args)
    when "Sales amount by gizmo type"
     get_sales_amount_by_gizmo(args)
    else
      raise NoMethodError
    end
  end

  ######################
  # Random helper crap #
  ######################

  def generate_report_data
    list = []
    @start_date = Date.parse(params[:conditions][:start_date])
    end_date = Date.parse(params[:conditions][:end_date])
    if is_line
      @start_date = back_up_to_last_thing(@start_date)
      end_date = back_up_to_last_thing(end_date)
    elsif is_bar
    else
      raise NoMethodError
    end
    if is_line
      (number_between_them(end_date) + 1).times{|x|
        list << get_this_one(x)
      }
    elsif is_bar
      list = get_bar_list.to_a
    else
      raise NoMethodError
    end
    list.delete_if{|x| x.nil?}
    @broken_down_by = params[:conditions][:breakdown_type].downcase.sub(/ly$/, "").sub(/i$/, "y")
    @title = get_title + " (broken down by #{@broken_down_by})"
    @data = {}
    @x_axis = []
    list.each{|x|
      @x_axis << x_axis_for(x)
    }
    @graph_x_axis = []
    @table_x_axis = {}
    @x_axis.each_with_index{|x,i|
      if is_line
        @graph_x_axis << graph_x_axis_for(x, list[i])
      elsif is_bar
        @graph_x_axis << list[i]
      else
        raise NoMethodError
      end
      if is_line
        @table_x_axis[x] = list[i].to_s
      elsif is_bar
        @table_x_axis[x] = @x_axis[i]
      else
        raise NoMethodError
      end
    }
    if is_line
      list.map!{|x|
        {:start_date => x.to_s, :end_date => second_timerange(x).to_s}
      }
    elsif is_bar
      list.map!{|x|
        {:start_date => @start_date.to_s, :end_date => end_date.to_s, :extract_type => extract_name_for_breakdown_type, :extract_value => x}
      }
    else
      raise NoMethodError
    end
    list.each{|args|
      if is_line
        args[:number_of_days] = (Date.strptime(args[:end_date]) - Date.strptime(args[:start_date])).ceil
      elsif is_bar
        args[:number_of_days] = 0
        array_of_dates(args[:start_date], args[:end_date]).each do |date|
          args[:number_of_days] += 1 if check_date_for_extract_type(args, date)
        end
      else
        raise NoMethodError
      end
    }
    resultlist = list.map{|args|
      get_thing_for_timerange(args)
    }
    lines = resultlist.map{|x| x.keys}.flatten.uniq
    lines.each{|x|
      @data[x] = []
    }
    resultlist.each{|thing|
      lines.each{|k|
        v = thing[k]
        v = 0 if v.nil?
        @data[k] << v
      }
    }
  end

  def array_of_dates(start, stop)
    start = Date.parse(start) if start.class == String
    stop = Date.parse(stop) if stop.class == String
    if start > stop
      temp = start
      start = stop
      stop = temp
    end
    stop += 1
    arr = []
    i = start
    while i != stop
      arr << i
      i = i + 1
    end
    return arr
  end

  def breakdown_types
    line_breakdown_types + bar_breakdown_types
  end

  def is_line
    line_breakdown_types.include?(params[:conditions][:breakdown_type])
  end

  def is_bar
    bar_breakdown_types.include?(params[:conditions][:breakdown_type])
  end

  def back_up_to_last_thing(date)
    temp = date
    until is_last_thing?(temp)
      temp = temp - 1
    end
    return temp
  end

  def created_at_conditions_for_report(args)
    conditions_with_daterange_for_report(args, "created_at")
  end

  def sql_for_report(model, conditions)
    c = Conditions.new
    c.apply_conditions(conditions)
    return DB.prepare_sql(c.conditions(model))
  end

  def conditions_with_daterange_for_report(args, field)
    h = {"#{field}_enabled" => "true", "#{field}_date_type" => "arbitrary", "#{field}_start_date" => args[:start_date], "#{field}_end_date" => args[:end_date], "#{field}_enabled" => "true"}
    conditions_for_report(args, field, h)
  end

  def conditions_for_report(args, field, extra_conditions = {})
    h = extra_conditions
    if args[:extract_type]
      h["extract_enabled"] = "true"
      h["extract_type"] = args[:extract_type]
      h["extract_value"] = args[:extract_value]
      h["extract_field"] = field
    end
    h["empty_enabled"] = "true"
    return params[:conditions].dup.delete_if{|k,v| [:start_date, :end_date, :report_type, :breakdown_type].map{|x| x.to_s}.include?(k)}.merge(h)
  end

  def call_income_report(args)
    r = ReportsController.new
    r.income_report(created_at_conditions_for_report(args))
  end

  def find_all_donations(args)
    c = Conditions.new
    c.apply_conditions(created_at_conditions_for_report(args))
    n = Donation.number_by_conditions(c)
  end

  def get_sales_money(args)
    res = DB.execute("SELECT SUM( reported_amount_due_cents )/100.0 AS amount
  FROM sales WHERE " + sql_for_report(Sale, conditions_with_daterange_for_report(args, "created_at")))
    return {:total => res.first["amount"]}
  end

  def get_donations_count(args)
    return {:count => find_all_donations(args).to_s}
  end

  def get_volunteer_hours_by_program(args)
    res = DB.execute("SELECT programs.description, SUM( duration )
  FROM volunteer_tasks
  LEFT JOIN volunteer_task_types ON volunteer_tasks.volunteer_task_type_id = volunteer_task_types.id
  LEFT JOIN volunteer_task_types AS programs ON volunteer_task_types.parent_id = programs.id
  WHERE #{sql_for_report(VolunteerTask, created_at_conditions_for_report(args))}
  GROUP BY programs.id, programs.description
  ORDER BY programs.description;")
    Hash[*res.to_a.collect{|x| [x["description"], x["sum"]]}.flatten]
  end

  def get_active_volunteers(args)
    res = DB.execute("SELECT count( distinct contact_id ) as vol_count
    FROM volunteer_tasks
    WHERE contact_id IN (
    SELECT xxx.contact_id
      FROM volunteer_tasks AS xxx
      WHERE xxx.date_performed BETWEEN
        ?::date AND ?::date
      GROUP BY xxx.contact_id
      HAVING SUM(xxx.duration) > #{Default['hours_for_discount'].to_f}) AND #{sql_for_report(VolunteerTask, conditions_for_report(args, "date_performed"))};", Date.strptime(args[:start_date]) - Default['days_for_discount'].to_f, args[:start_date])
    final = 0
    if res.first
      final = res.first['vol_count']
    end
    return {:active => final}
  end

  def get_sales_amount_by_gizmo(args)
    res = DB.execute("SELECT SUM( unit_price_cents * gizmo_count )/100.0 AS due
FROM gizmo_events
WHERE sale_id IS NOT NULL
AND #{sql_for_report(GizmoEvent, created_at_conditions_for_report(args))}")
    return {:amount => res.first["due"]}
  end

  def get_donation_count_by_gizmo(args)
    res = DB.execute("SELECT SUM( gizmo_count ) AS count
FROM gizmo_events
WHERE donation_id IS NOT NULL
AND #{sql_for_report(GizmoEvent, created_at_conditions_for_report(args))}")
    return {:count => res.first["count"]}
  end

  def get_sales_count_by_gizmo(args)
    res = DB.execute("SELECT SUM( gizmo_count ) AS count
FROM gizmo_events
WHERE sale_id IS NOT NULL
AND #{sql_for_report(GizmoEvent, created_at_conditions_for_report(args))}")
    return {:count => res.first["count"]}
  end

  def get_average_frontdesk(args)
    thing = call_income_report(args)
    thing = thing[:donations]["total real"] # WHY IS THERE A SPACE!?!?!
    suggested = thing["suggested"][:total] / 100.0
    fees = thing["fees"][:total] / 100.0
    number = find_all_donations(args)
    total = suggested + fees
    suggested = suggested / number
    fees = fees / number
    total = total / number
    suggested = 0.0 if suggested.nan?
    fees = 0.0 if fees.nan?
    total = 0.0 if total.nan?
    suggested = sprintf("%.2f", suggested).to_f
    fees = sprintf("%.2f", fees).to_f
    total = sprintf("%.2f", total).to_f
    {:fees => fees, :suggested => suggested, :total => total}
  end

  def get_income_for_timerange(args)
    thing = call_income_report(args)[:grand_totals]["total"]["total"][:total] / 100.0
    {:income => thing}
  end

  # used for quarterly
  def increase_arr(d)
    d[1] += 3
    if d[1] > 12
      d[1] = 1
      d[0] += 1
    end
    d
  end
end
