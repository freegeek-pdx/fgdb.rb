class WorkedShiftsController < ApplicationController
  layout :with_sidebar
  before_filter :be_stupid
  before_filter :common_logic
  helper :table

  protected

  public

  NH = {"jobs" => "name",
    "wc_categories" => "description",
    "programs" => "name",
    "income_streams" => "description",
    "worker_types" => "name",
    "workers" => "name"}

  def breaks
    @conditions = Conditions.new
  end

  def breaks_report
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    conds = @conditions.conditions(WorkedShift)
    conds[0] = "SELECT workers.name, SUM(CASE WHEN(jobs.name LIKE 'Paid Break') THEN 0.0 ELSE duration END) AS total, SUM(CASE WHEN(jobs.name LIKE 'Paid Break') THEN duration ELSE 0.0 END) AS breaks FROM worked_shifts JOIN jobs ON worked_shifts.job_id = jobs.id  JOIN workers ON worked_shifts.worker_id = workers.id WHERE #{conds[0]} GROUP BY 1 ORDER BY 1;"
    @result = DB.exec(conds)
  end

  def type_totals
    @types_of_types = NH.keys
    @multi_enabled = true
  end

  def type_totals_report
    @defaults = Conditions.new
    if params[:defaults].nil?
      redirect_to :action => 'type_totals'
      return
    end
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s

    @by_percentage = params[:worked_shift][:by_percentage] == "1"
    @include_empty = params[:worked_shift][:include_empty] == "1"
    @row_table = params[:worked_shift][:row_name]
    @col_table = params[:worked_shift][:col_name]
    @start_date = @end_date = "2010-06-24"

    def get_table_labels(table)
      res = DB.exec("SELECT id, #{NH[table]} AS label FROM #{table}")
      h = {}
      res.each{|x|
        h[x["id"]] = x["label"].downcase
      }
      return h
    end

    row_labels = get_table_labels(@row_table)
    col_labels = get_table_labels(@col_table)

    res = DB.exec("SELECT #{@row_table}.id AS row_id, #{@col_table}.id AS col_id, SUM(duration) AS duration
FROM worked_shifts
LEFT OUTER JOIN jobs on jobs.id = job_id
LEFT OUTER JOIN wc_categories ON jobs.wc_category_id = wc_categories.id
LEFT OUTER JOIN programs ON programs.id = jobs.program_id
LEFT OUTER JOIN income_streams ON income_streams.id = jobs.income_stream_id
LEFT OUTER JOIN workers ON worker_id = workers.id
LEFT OUTER JOIN workers_worker_types ON workers_worker_types.worker_id = workers.id AND (workers_worker_types.effective_on <= worked_shifts.date_performed OR workers_worker_types.effective_on IS NULL) AND (workers_worker_types.ineffective_on > worked_shifts.date_performed OR workers_worker_types.ineffective_on IS NULL)
LEFT OUTER JOIN worker_types ON worker_types.id = workers_worker_types.worker_type_id
WHERE #{DB.prepare_sql(@defaults.conditions(WorkedShift))}
GROUP BY 1,2;")

    template_row_hash = {}
    table_hash = {}
    row_subtotal = {}

    col_labels.each{|k,v|
      template_row_hash[k] = 0.0
    }

    def sort_hash(h)
      h.to_a.sort_by{|x| t = x.last.downcase; t == "unset" ? "zzzzz-last-unset" : t}.map(&:first)
    end

    row_labels.each{|k,v|
      table_hash[k] = template_row_hash.dup
      row_subtotal[k] = 0.0
    }

    col_subtotal = template_row_hash.dup

    total = 0.0

    res.to_a.each {|x|
      d = x["duration"].to_f
      ri = x["row_id"] || "NULL"
      ci = x["col_id"] || "NULL"
      if ri == "NULL"
        table_hash[ri] ||= template_row_hash.dup
	row_subtotal[ri] ||= 0.0
      end
      if ci == "NULL"
      	table_hash[ri][ci] ||= 0.0
	col_subtotal[ci] ||= 0.0
      end
      table_hash[ri][ci] += d
      row_subtotal[ri] += d
      col_subtotal[ci] += d
      total += d
    }

    row_labels["NULL"] = "unset" if table_hash.keys.include?("NULL")
    col_labels["NULL"] = "unset" if table_hash.values.map(&:keys).flatten.uniq.include?("NULL")

    sorted_row_ids = sort_hash(row_labels)
    sorted_col_ids = sort_hash(col_labels)

    if @by_percentage
      sorted_row_ids.each{|ri|
        total = row_subtotal[ri]
        sorted_col_ids.each{|ci|
          table_hash[ri][ci] ||= 0.0
          table_hash[ri][ci] = (table_hash[ri][ci] / total) * 100 unless total == 0.0
          table_hash[ri][ci] = sprintf '%.2f%',table_hash[ri][ci]
        }
        row_subtotal[ri] = (total == 0.0 ? 0 : 1) * 100.0
        row_subtotal[ri] = sprintf '%.2f%', row_subtotal[ri]
      }
    end

    def value_is_zero(value)
      value == (value.class == String ? '0.00%' : 0.0)
    end

    unless @include_empty
      sorted_row_ids = sorted_row_ids.select{|x| !value_is_zero(row_subtotal[x])}
      sorted_col_ids = sorted_col_ids.select{|x| !value_is_zero(col_subtotal[x])}
    end

    table = []
    table << ["", sorted_col_ids.map{|x| col_labels[x]}, "total"].flatten
    sorted_row_ids.each{|x|
      a = [row_labels[x]]
      h = table_hash[x]
      sorted_col_ids.each{|y|
        a << (h[y] || 0.0)
      }
      a << row_subtotal[x]
      table << a
    }

    a = ["total"]
    sorted_col_ids.each{|y|
      a << col_subtotal[y]
    }
    a << total
    table << a unless @by_percentage

    @result = table
  end
  protected
  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'worked_shifts')
  end
  def default_my_form
    @worker ||= (@current_user.contact ? @current_user.contact.worker : nil)
    @date ||= Date.today
  end

  private

  filter_parameter_logging "password"

  def applied_user
    has_required_privileges('/modify_all_workers') ? current_user : (@worker ? @worker.contact ? @worker.contact.user : nil : nil)
  end

  def mark_activity
    session['worker_access_id'] = applied_user.id
    session['worker_access_last'] = DateTime.now
  end

  def handle_session
    value = session['worker_access_last']
    @session_allowed = applied_user && (session['worker_access_id'] == applied_user.id) &&(value && (value >= eval(Default["staff_hours_timeout"])))
  end

  def authenticate
    default_my_form
    handle_session
    user = applied_user
    if user and User.authenticate(user.login, params[:worked_shift][:password])
      mark_activity
      user.will_not_updated_timestamps!
      user.last_logged_in = Date.today
      user.save
      @session_allowed = true
    else
      flash[:error] = user ? "Incorrect password for user #{user.login}" : "That worker has no user login"
    end
  end

  public
  def index
    default_my_form
    handle_session
    if !@session_allowed and params[:worked_shift] and params[:worked_shift].keys.include?("password")
      authenticate
    end
    if request.method == :post and params[:worked_shift] and params[:worked_shift].keys.include?("password")
      params[:worked_shift].delete("password")
      params[:worked_shift].delete("L") # unimportant
      redirect_to(params)
    end
    if @worker and @session_allowed
      mark_activity
      @shifts = @worker.shifts_for_day(@date)
      @logged_already = @shifts.shift
      @messages = @shifts.shift
      @shifts = @shifts.select{|x| !(x.job_id.nil? && x.duration == 0)}
    end
  end

  def individual
    default_my_form
  end

  include WorkedShiftsHelper
  def weekly_workers_report
    @start = @date.dup
    @end = @date.dup
    @start -= 1 while @start.wday != 1 # Monday
    @end += 1 while @end.wday != 0 # Sunday
    @result = Worker.effective_in_range(@start, @end).real_people.sort_by(&:sort_by).map{|x| a = (@start..@end).to_a.map{|y| HtmlTag.new("a", {:href => url_for_log(x, y)}, [], x.hours_effective_on_day(y))}; [x.sort_by, (x.worker_type_on_day(@end) || x.worker_type_on_day(@start)).name, a, a.inject(0.0){|t,x| t+=x.content}.to_s].flatten}
    header_array = ["Worker", "Worker Type", (@start..@end).to_a.map{|x| x.strftime("%A")}, "Total"].flatten
    a = (2..8).to_a.map{|i|
      @result.inject(0.0){|t,x|
        t+=x[i].content
      }
    }
    footer_array = ["Total", "", a, a.inject(0.0){|t,x| t+=x}.to_s].flatten
    @result.unshift(header_array)
    @result.push(footer_array)
    @title = "Weekly worker report for week of #{@start.to_s} to #{@end.to_s}"
  end

  def payroll_report
    begin
      @enddate = Date.parse(params[:worked_shift][:end_date]) if params[:worked_shift].keys.include?("end_date") and params[:worked_shift][:end_date] != ""
    rescue
    end
    if !defined?(@date)
      flash[:error] = "The date entered was not a valid date"
      redirect_to :back
      return
    end
    if @enddate
      @pay_periods = PayPeriod.find(:all, :conditions => ['start_date <= ? AND end_date >= ?', @enddate, @date]).sort_by(&:start_date)
    else
      @pay_periods = PayPeriod.find_for_date(@date)
      @pay_periods = @pay_periods ? [@pay_periods] : []
    end
    theworkers = (@pay_periods.length > 0) ? Worker.effective_in_range(@pay_periods.first.start_date, @pay_periods.last.end_date).real_people.sort_by(&:sort_by) : []
    @workers = []
    @pay_periods.each{|p|
      myworkers = theworkers.map{|x| x.to_payroll_hash(p)}
      myworkers.each_with_index{|x,i|
        if ! (h = @workers[i])
          @workers[i] = x
        else
          h[:hours] += x[:hours]
          h[:holiday] += x[:holiday]
          h[:pto] += x[:pto]
          h[:overtime] += x[:overtime]
        end
      }
    }
    # array of hashes with keys: name type hours pto overtime holiday
    @types = @workers.map{|x| x[:type]}.uniq.sort
    @types = @types.map{|x|
      h = {}
      h[:name] = x
      arr = @workers.select{|y| y[:type] == x}
      h[:hours] = arr.inject(0.0){|t, x| t+= x[:hours]}
      h[:holiday] = arr.inject(0.0){|t, x| t+= x[:holiday]}
      h[:pto] = arr.inject(0.0){|t, x| t+= x[:pto]}
      h[:overtime] = arr.inject(0.0){|t, x| t+= x[:overtime]}
      h
    }
    h = {}
    h[:name] = "total"
    h[:hours] = @types.inject(0.0){|t, x| t+= x[:hours]}
    h[:holiday] = @types.inject(0.0){|t, x| t+= x[:holiday]}
    h[:pto] = @types.inject(0.0){|t, x| t+= x[:pto]}
    h[:overtime] = @types.inject(0.0){|t, x| t+= x[:overtime]}
    @types << h
    total = h[:hours] + h[:overtime] + h[:holiday] + h[:pto]
    @types.each{|x|
      percent = 0.0
      this = x[:hours] + x[:overtime] + x[:holiday] + x[:pto]
      percent = this / total if total > 0
      x[:percent] = percent unless x[:name] == "total"
    }
  end

  def update_shift_totals
    handle_session
    if @worker and @session_allowed
      mark_activity
    end
    @hours = params[:worked_shift][:hours_today].to_f
    render :action => 'update_shift_totals.rjs'
  end

  def save
    if !params[:worked_shift]
      redirect_to :action => "index"
      return
    end
#    @logged_already = true
#    @shifts = process_shifts(params[:shifts])
#    render :action => "edit"
    handle_session
    if !@session_allowed and params[:worked_shift] and params[:worked_shift].keys.include?("password")
      authenticate
    end
    params[:worked_shift].delete("password")
    if @worker and @session_allowed
      mark_activity
      if params[:worked_shift]
        process_shifts(params[:shifts])
      else
        flash[:error] = "ERROR: Hours were not saved. Please choose a date to save hours for."
      end
    else
      flash[:error] = "ERROR: Hours were not saved. Please choose a worker and authenticate."
    end
    redirect_to :action => "index"
  end

  private

  def process_shifts(shifts)
    shifts = shifts.nil? ? [{"duration" => "0", "job_id" => nil}] : shifts.values
    to_delete = WorkedShift.find(:all, :conditions => ["date_performed = ? AND worker_id = ?", @date, @worker.id])
    found = []
    new = []
    shifts.each{|x|
      s = nil
      if x[:id] and x[:id] != "undefined"
        s = WorkedShift.find_by_id(x[:id])
      end
      if s
        s.update_attributes(params[:worked_shift].merge(x))
        found << s
      else
        s = WorkedShift.new(params[:worked_shift].merge(x))
        new << s
      end
    }
    to_delete = to_delete - found
    to_delete.each{|x| x.destroy}
    new.each{|x| x.save!}
    new = found + new
    found = nil
    return new
  end

  def common_logic
    return if ! params[:worked_shift]
    @worker = Worker.find_by_contact_id(params[:worked_shift][:contact_id]) if params[:worked_shift].keys.include?("contact_id")
    @worker = Worker.find_by_id(params[:worked_shift][:worker_id]) if params[:worked_shift].keys.include?("worker_id")
    begin
      @date = Date.parse(params[:worked_shift][:date_performed]) if params[:worked_shift].keys.include?("date_performed")
    rescue
    end
  end
end
