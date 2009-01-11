class GraphicReportsController < ApplicationController
  layout :with_sidebar

  def view
    start_date = Date.parse(params[:conditions][:start_date])
    number_of_weeks = params[:conditions][:number].to_i
    list = []
    number_of_weeks.times{|x|
      list << start_date + (7*x)
    }
    @title = "Income report"
    @data = {}
    @x_axis = []
    list.each{|x|
      @x_axis << "Week of " + x.to_s
    }
    @data[:income] = []
    list.each{|x|
      @data[:income] << get_thing_for_timerange(x.to_s, second_timerange(x))
    }
  end

  def index
    @conditions = OpenStruct.new
  end

  def second_timerange(first)
    (first + 6).to_s
  end

  def get_thing_for_timerange(*args)
    case params[:conditions][:report_type]
      when "Income"
      return get_income_for_timerange(*args)
    end
  end

  def get_income_for_timerange(start_date, end_date)
    r = ReportsController.new
    r.income_report({"created_at_enabled" => "true", "created_at_date_type" => "arbitrary", "created_at_start_date" => start_date, "created_at_end_date" => end_date})[:grand_totals]["total"]["total"][:total] / 100.0
  end
end
