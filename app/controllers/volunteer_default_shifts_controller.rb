class VolunteerDefaultShiftsController < ApplicationController
  protected
  def get_required_privileges
    a = super
    a << {:privileges => ['admin_skedjul']}
    a
  end
  public

  layout :with_sidebar

  helper :skedjul

  def generate
    gconditions = Conditions.new
    gconditions.apply_conditions(params[:gconditions])
    begin
      startd, endd = Date.parse(params[:date_range][:start_date]), Date.parse(params[:date_range][:end_date])
    rescue
      flash[:error] = "Generate error: A valid date ranges was not given"
      redirect_to :back
      return
    end
    if params[:date_range][:do_shifts] == "1"
      VolunteerDefaultShift.generate(startd, endd, gconditions)
    end
    if params[:date_range][:do_resources] == "1"
      ResourcesVolunteerDefaultEvent.generate(startd, endd, gconditions)
    end
    redirect_to :controller => 'assignments', :action => "index", :conditions => params[:gconditions].merge({:date_start_date => params[:date_range][:start_date], :date_end_date => params[:date_range][:end_date], :date_date_type => "arbitrary", :date_enabled => "true"})
  end

  def index
    @multi_enabled = true
    if params[:conditions]
    @skedj = Skedjul.new({
      :generate_param_key => "date_range",
      :generate_conditions => ["sked", "roster"],
      :conditions => ["weekday", "sked", "roster", "volunteer_task_type"],

      :block_method_name => "volunteer_default_shifts.volunteer_default_events.weekday_id",
      :block_method_display => "volunteer_default_events.weekdays.name",
      :block_start_time => "volunteer_default_events.weekdays.start_time",
      :block_end_time => "volunteer_default_events.weekdays.end_time",

      :left_unique_value => "volunteer_default_shifts.left_unique_value", # model
      :left_method_name => "volunteer_default_shifts.left_method_name",
      :left_sort_value => "(coalesce(volunteer_task_types.description, volunteer_default_events.description)), volunteer_default_shifts.description",
      :left_table_name => "volunteer_task_types",
      :left_link_action => "new_default_shift",
      :left_link_id => "volunteer_task_types.id",

      :thing_start_time => "volunteer_default_shifts.start_time",
      :thing_end_time => "volunteer_default_shifts.end_time",
      :thing_table_name => "volunteer_default_shifts",
      :thing_description => "describe",
      :thing_link_id => "volunteer_default_shifts.id",
      :thing_links => [[:edit, :popup], [:destroy, :confirm]]

      }, params)

    @skedj.find({:include => [:volunteer_task_type => [], :volunteer_default_event => [:weekday]]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "assignments/index", :layout => :with_sidebar
    end
  end

  def edit
    @volunteer_default_shift = VolunteerDefaultShift.find(params[:id])
    redirect_to({:controller => "volunteer_default_events", :action => "edit", :id => @volunteer_default_shift.volunteer_default_event_id})
  end

  def destroy
    @volunteer_default_shift = VolunteerDefaultShift.find(params[:id])
    @volunteer_default_shift.destroy

    redirect_skedj(request.env["HTTP_REFERER"], @volunteer_default_shift.volunteer_default_event.weekday.name)
  end
end
