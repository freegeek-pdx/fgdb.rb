class VolunteerDefaultEventsController < ApplicationController
  def add_shift
    ve = nil
    if !params["id"].blank?
      ve = VolunteerDefaultEvent.find(params["id"])
    else
      ve = VolunteerDefaultEvent.new
    end
    vs = ve.volunteer_default_shifts.new
    vs.program = Program.find_by_name("intern")
    vs.slot_count = 1
    vs.volunteer_default_event_id = ve.id if ve.id
    vs.volunteer_default_event = ve
    a = vs.default_assignments.new
    a.volunteer_default_shift = vs
    vs.stuck_to_assignment = vs.not_numbered = true
    @assignments = vs.default_assignments = [a]
    @referer = request.env["HTTP_REFERER"]
    @my_url = {:action => "create_shift", :id => params[:id]}
    @assignment = a
    render :template => 'assignments/edit'
  end

  def create_shift
    ve = nil
    params["default_assignment"] ||= {}
    if !params["id"].blank?
      ve = VolunteerDefaultEvent.find(params["id"])
    else
      if (params["default_assignment"]["volunteer_default_shift_attributes"].nil? || params["default_assignment"]["volunteer_default_shift_attributes"]["roster_id"].blank? || params["default_assignment"]["set_weekday_id"].blank?)
        ve = VolunteerDefaultEvent.new
      else
        ve = Roster.find_by_id(params["default_assignment"]["volunteer_default_shift_attributes"]["roster_id"]).vol_event_for_weekday(params["default_assignment"]["set_weekday_id"])
      end
    end
    vs = ve.volunteer_default_shifts.new
    vs.slot_count = 1
    vs.volunteer_default_event_id = ve.id if ve.id
    vs.volunteer_default_event = ve
    vs.stuck_to_assignment = vs.not_numbered = true
    vs.attributes=(params["default_assignment"]["volunteer_default_shift_attributes"])
    a = vs.default_assignments.new
    a.volunteer_default_shift = vs
#    a.volunteer_shift_id = vs.id
    a.attributes = (params["default_assignment"])
    @assignments = vs.default_assignments = [a]
    vs.set_values_if_stuck
    vs.default_assignments = []
    @success = a.valid? && vs.save
    rt = params[:default_assignment].delete(:redirect_to)
    @my_url = {:action => "create_shift", :id => params[:id]}
    @assignment = a
    if @success
      vs = vs.reload
      @assignment = a = vs.default_assignments.new
      a.volunteer_default_shift = vs
      #    a.volunteer_shift_id = vs.id
      a.attributes = (params["default_assignment"])
      @assignments = vs.default_assignments = [a]

      if !@success
        vs.destroy
      end
    end
    if @success # and @assignment.volunteer_shift.save
      redirect_skedj(rt, ve.weekday.name)
    else
      render :template => 'assignments/edit'
    end
  end


  protected
  public
  layout :with_sidebar

  def index
#    @volunteer_default_events = VolunteerDefaultEvent.find(:all)
    redirect_to :controller => "default_assignments"
  end

  def show
    @volunteer_default_event = VolunteerDefaultEvent.find(params[:id])
  end

  def new
    @volunteer_default_event = VolunteerDefaultEvent.new
  end

  def edit
    @volunteer_default_event = VolunteerDefaultEvent.find(params[:id])
    @referer = request.env["HTTP_REFERER"]
  end

  def copy
    begin
      vol_event = VolunteerDefaultEvent.find_by_id(params[:id])
    rescue
      flash[:error] = "Could not find volunteer event"
      redirect_to :back
      return
    end
    begin
      weekday = Weekday.find_by_id(params[:copy][:weekday_id])
    rescue
      flash[:error] = "Could not find weekday, please select one"
      redirect_to :back
      return
    end
    new_event = vol_event.copy_to(weekday, hours_val(params[:copy]))
    redirect_to :action => "show", :id => new_event.id
  end

  def create
    @volunteer_default_event = VolunteerDefaultEvent.new(params[:volunteer_default_event])

    _save
    if @volunteer_shifts.select{|x| !x.valid?}.length == 0 && @resources.select{|x| !x.valid?}.length == 0 && @volunteer_default_event.valid? && @volunteer_default_event.save
      _after_save
      flash[:notice] = 'VolunteerDefaultEvent was successfully created.'
      redirect_to({:action => "show", :id => @volunteer_default_event.id})
    else
      render :action => "new"
    end
  end

  def update
    @volunteer_default_event = VolunteerDefaultEvent.find(params[:id])
    rt = params[:volunteer_default_event].delete(:redirect_to)

    _save
    if @volunteer_shifts.select{|x| !x.valid?}.length == 0 && @resources.select{|x| !x.valid?}.length == 0 && @volunteer_default_event.valid? && @volunteer_default_event.update_attributes(params[:volunteer_default_event])
      _after_save
      flash[:notice] = 'VolunteerDefaultEvent was successfully updated.'
      redirect_skedj(rt, @volunteer_default_event.weekday.name)
    else
      render :action => "edit"
    end
  end

  def _save
    @volunteer_shifts = apply_line_item_data(@volunteer_default_event, VolunteerDefaultShift, 'volunteer_shifts')
    @resources = apply_line_item_data(@volunteer_default_event, ResourcesVolunteerDefaultEvent, 'resources_volunteer_events')
  end

  def _after_save
    @volunteer_shifts.each{|x| x.save!}
    @resources.each{|x| x.save!}
  end

  def destroy
    @volunteer_default_event = VolunteerDefaultEvent.find(params[:id])
    @volunteer_default_event.destroy

    redirect_to({:action => "index"})
  end
end
