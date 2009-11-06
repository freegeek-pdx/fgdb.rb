class WorkedShiftsController < ApplicationController
  layout :with_sidebar
  before_filter :be_stupid

  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'worked_shifts')
  end

  def edit
    common_logic
    @shifts = @worker.shifts_for_day(@date)
    @logged_already = @shifts.shift
  end

  def save
    common_logic
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
    @worker = Worker.find_by_id(params[:worked_shift][:worker_id])
    @date = params[:worked_shift][:date_performed]
  end
end
