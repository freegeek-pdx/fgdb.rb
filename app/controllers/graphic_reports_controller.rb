class GraphicReportsController < ApplicationController
  layout :with_sidebar

  def view
    generate_report_data
  end

  def index
    @report_types = report_types
    @breakdown_types = breakdown_types
  end

  private

  #########################
  # Time range type stuff #
  #########################

  # should return the total number of things that should be on the x
  # axis, minus one (this makes logical sense for simplicity)
  def number_between_them(end_date)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      (end_date - @start_date).to_i / 7
    when "Quarterly"
      # EWWWW. this whole number_between_them needs to be eliminated
      num = 0
      curdate = @start_date
      until curdate == end_date
        curdate = Date.parse(increase_arr(curdate.to_s.split("-").map{|x| x.to_i}).join("-"))
        num += 1
      end
      return num
    end
  end

  # returns true if this is a "good" date (ie, the beginning of the
  # week), or if it needs to be backed up further
  def is_last_thing?(date)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      date.strftime("%a") == "Sun"
    when "Quarterly"
      a = date.to_s.split("-")
      return [1,4,7,10].include?(a[1].to_i) && a[2] == "01"
    end
  end

  # get the date object for number "breakdowns" after the start date
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
    end
  end

  # convert a date object into the string that should be put on the x axis
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
    end
  end

  # takes in what x_axis_for outputted and reformats it for the graph
  # (make it shorter and such)
  def graph_x_axis_for(x_axis)
    case params[:conditions][:breakdown_type]
    when "Quarterly"
      if @x_axis.length > 6
        # make it shorter (might not have to do this if a better graphing thingy is used)
        if x_axis.match(/Q1/)
          return x_axis.sub(/-Q1/, "")
        else
          return ""
        end
      end
    end
    return x_axis
  end

  # get the last day in the range
  def second_timerange(first)
    case params[:conditions][:breakdown_type]
    when "Weekly"
      first + 6
    when "Quarterly"
      Date.parse(increase_arr(first.to_s.split("-").map{|x| x.to_i}).join("-")) - 1
    end
  end

  # list of breakdown types
  def breakdown_types
    ["Quarterly", "Weekly"]
  end

  #####################
  # Report type stuff #
  #####################

  # list of report types
  def report_types
    ["Average Frontdesk Income", "Income"]
  end

  # returns the title for that report type
  def get_title
    case params[:conditions][:report_type]
      when "Income"
      "Income report"
      when "Average Frontdesk Income"
      "Report of Average Income at Front Desk"
    end
  end

  # calls a method specific to that report that takes two arguements,
  # a start date and an end date, and returns a hash (one element for
  # each line) with the key being the name of the line and the value
  # the number to be plotted for that date range
  def get_thing_for_timerange(*args)
    case params[:conditions][:report_type]
    when "Income"
      get_income_for_timerange(*args)
    when "Average Frontdesk Income"
      get_average_frontdesk(*args)
    end
  end

  ######################
  # Random helper crap #
  ######################

  def generate_report_data
    list = []
    @start_date = Date.parse(params[:conditions][:start_date])
    @start_date = back_up_to_last_thing(@start_date)
    end_date = Date.parse(params[:conditions][:end_date])
    end_date = back_up_to_last_thing(end_date)
    (number_between_them(end_date) + 1).times{|x|
      list << get_this_one(x)
    }
    @title = get_title
    @data = {}
    @x_axis = []
    list.each{|x|
      @x_axis << x_axis_for(x)
    }
    @graph_x_axis = []
    @x_axis.each{|x|
      @graph_x_axis << graph_x_axis_for(x)
    }
    list.each{|x|
      get_thing_for_timerange(x.to_s, second_timerange(x).to_s).each{|k,v|
        if !@data[k]
          @data[k] = []
        end
        @data[k] << v
      }
    }
    if false # || true
      require 'pp'
      pp @data
      render :text => "BLAH"
    end
  end

  def back_up_to_last_thing(date)
    temp = date
    until is_last_thing?(temp)
      temp = temp - 1
    end
    return temp
  end

  def created_at_conditions_for_report(start_date, end_date)
    {"created_at_enabled" => "true", "created_at_date_type" => "arbitrary", "created_at_start_date" => start_date, "created_at_end_date" => end_date}
  end

  def call_income_report(*args)
    r = ReportsController.new
    r.income_report(created_at_conditions_for_report(*args))
  end

  def find_all_donations(*args)
    c = Conditions.new
    c.apply_conditions(created_at_conditions_for_report(*args))
    n = Donation.number_by_conditions(c)
  end

  def get_average_frontdesk(*args)
    thing = call_income_report(*args)[:donations].select{|k,v| !k.match(/total/)}.map{|x| x[1]}.map{|x| {:required => x["fees"][:total], :suggested => x["suggested"][:total]}}
    suggested = thing.map{|x| x[:suggested]}.inject(0.0){|x,y| x+y} / 100.0
    fees = thing.map{|x| x[:required]}.inject(0.0){|x,y| x+y} / 100.0
    number = find_all_donations(*args)
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

  def get_income_for_timerange(*args)
    thing = call_income_report(*args)[:grand_totals]["total"]["total"][:total] / 100.0
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
