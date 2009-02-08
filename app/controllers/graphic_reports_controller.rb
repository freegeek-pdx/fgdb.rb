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
#    @cleaned_conditions = params[:conditions].dup.delete_if{|k,v| [:start_date, :end_date, :report_type, :breakdown_type].map{|x| x.to_s}.include?(k)}
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

  # convert a date object into the string that should be put on the x
  # axis, and on the left side of the table
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

  # list of breakdown types
  def breakdown_types
    ["Yearly", "Quarterly", "Monthly", "Weekly", "Daily"]
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
    list.delete_if{|x| x.nil?}
    @title = get_title + " (broken down by #{params[:conditions][:breakdown_type].downcase.sub(/ly$/, "").sub(/i$/, "y")})"
    @data = {}
    @x_axis = []
    list.each{|x|
      @x_axis << x_axis_for(x)
    }
    @graph_x_axis = []
    @x_axis.each_with_index{|x,i|
      @graph_x_axis << graph_x_axis_for(x, list[i])
    }
    list.each{|x|
      get_thing_for_timerange(x.to_s, second_timerange(x).to_s).each{|k,v|
        if !@data[k]
          @data[k] = []
        end
        @data[k] << v
      }
    }
  end

  def back_up_to_last_thing(date)
    temp = date
    until is_last_thing?(temp)
      temp = temp - 1
    end
    return temp
  end

  def created_at_conditions_for_report(start_date, end_date)
    h = {"created_at_enabled" => "true", "created_at_date_type" => "arbitrary", "created_at_start_date" => start_date, "created_at_end_date" => end_date, "created_at_enabled" => "true"}
#    return @cleaned_conditions.merge
    return h
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
    thing = call_income_report(*args)
    thing = thing[:donations]["total real"] # WHY IS THERE A SPACE!?!?!
    suggested = thing["suggested"][:total] / 100.0
    fees = thing["fees"][:total] / 100.0
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
