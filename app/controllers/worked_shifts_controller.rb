class WorkedShiftsController < ApplicationController
  layout :with_sidebar
  before_filter :be_stupid
  before_filter :common_logic
  helper :table

  before_filter :needs_beancounter_or_me

  def needs_beancounter_or_me
#    contact_id = @worker ? (@worker.contact ? @worker.contact.id : nil) : nil
    roles = ['BEAN_COUNTER', 'SKEDJULNATOR']
    if params[:action].match(/^(weekly_worker|payroll)/)
      return requires_role(*roles)
    else
      return requires_staff
    end
  end

  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'worked_shifts')
  end

  def edit
    @shifts = @worker.shifts_for_day(@date)
    @logged_already = @shifts.shift
  end

  def weekly_workers_report
    @start = @date.dup
    @end = @date.dup
    @start -= 1 while @start.wday != 1 # Monday
    @end += 1 while @end.wday != 0 # Sunday
    @result = Worker.effective_in_range(@start, @end).sort_by(&:sort_by).map{|x| a = (@start..@end).to_a.map{|y| x.hours_worked_on_day(y)}; [x.sort_by, a, a.inject(0.0){|t,x| t+=x}.to_s].flatten}
    header_array = ["Worker", (@start..@end).to_a.map{|x| x.strftime("%A")}, "Total"].flatten
    a = (1..7).to_a.map{|i|
      @result.inject(0.0){|t,x|
        t+=x[i]
      }
    }
    footer_array = ["Total", a, a.inject(0.0){|t,x| t+=x}.to_s].flatten
    @result.unshift(header_array)
    @result.push(footer_array)
    @title = "Weekly worker report for week of #{@start.to_s} to #{@end.to_s}"
  end

  def payroll_report
    pay_period = PayPeriod.find_for_date(@date) || raise
    @workers = Worker.effective_in_range(pay_period)
#    @workers = [Worker.find(6144)].flatten
    @workers = @workers.map{|x| x.to_payroll_hash(pay_period)}
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
  end

  def update_shift_totals
    @hours = params[:worked_shift][:hours_today].to_f
    render :action => 'update_shift_totals.rjs'
  end

  def save
#    @logged_already = true
#    @shifts = process_shifts(params[:shifts].values)
#    render :action => "edit"
    process_shifts(params[:shifts].values)
    redirect_to :action => "index"
  end

  private

  def process_shifts(shifts)
    to_delete = WorkedShift.find(:all, :conditions => ["date_performed = ?", @date])
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
