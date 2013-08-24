class VolunteerDefaultShiftsController < ApplicationController
  protected
  public

  layout :with_sidebar

  helper :skedjul

  def generate
    do_volskedj_generate('assignments')
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
    begin
      @volunteer_default_shift = VolunteerDefaultShift.find(params[:id])
      redirect_to({:controller => "volunteer_default_events", :action => "edit", :id => @volunteer_default_shift.volunteer_default_event_id})
    rescue
      flash[:jsalert] = $!.to_s
      redirect_to :back
    end
  end

  def destroy
    @volunteer_default_shift = VolunteerDefaultShift.find(params[:id])
    @volunteer_default_shift.destroy

    redirect_skedj(request.env["HTTP_REFERER"], @volunteer_default_shift.volunteer_default_event.weekday.name)
  end
end
