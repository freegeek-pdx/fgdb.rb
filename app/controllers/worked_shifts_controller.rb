class WorkedShiftsController < ApplicationController
  layout :with_sidebar
  before_filter :be_stupid
  before_filter :common_logic
  helper :table

  before_filter :needs_beancounter_or_me

  def needs_beancounter_or_me
#    contact_id = @worker ? (@worker.contact ? @worker.contact.id : nil) : nil
    roles = ['BEAN_COUNTER', 'SKEDJULNATOR']
    if params[:action].match(/^(weekly_worker|payroll|type_totals)/)
      return requires_role(*roles)
    else
      return requires_staff
    end
  end

  NH = {"jobs" => "name",
    "wc_categories" => "description",
    "programs" => "name",
    "income_streams" => "description",
    "worker_types" => "name",
    "workers" => "name"}

  def type_totals
    @types_of_types = NH.keys
  end

  def type_totals_report
    @defaults = Conditions.new
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s

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
WHERE #{ActiveRecord::Base.send(:sanitize_sql_for_conditions, @defaults.conditions(WorkedShift))}
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
    table << a

    @result = table
  end

  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'worked_shifts')
  end

  def edit
    @shifts = @worker.shifts_for_day(@date)
    @logged_already = @shifts.shift
    @shifts = @shifts.select{|x| !(x.job_id.nil? && x.duration == 0)}
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
    @pay_period = PayPeriod.find_for_date(@date) || raise
    @workers = Worker.effective_in_range(@pay_period).real_people.sort_by(&:sort_by)
#    @workers = [Worker.find(6144)].flatten
    @workers = @workers.map{|x| x.to_payroll_hash(@pay_period)}
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
    @hours = params[:worked_shift][:hours_today].to_f
    render :action => 'update_shift_totals.rjs'
  end

  def save
#    @logged_already = true
#    @shifts = process_shifts(params[:shifts])
#    render :action => "edit"
    process_shifts(params[:shifts])
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
    @worker = Worker.find_by_id(params[:worked_shift][:worker_id]) if params[:worked_shift].keys.include?("worker_id")
    @date = Date.parse(params[:worked_shift][:date_performed]) if params[:worked_shift].keys.include?("date_performed")
  end
end
