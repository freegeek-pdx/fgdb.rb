class VolunteerShiftsController < ApplicationController
  protected
  public

  layout :with_sidebar

  helper :skedjul

  def index
    @multi_enabled = true
    if params[:conditions]
    @skedj = Skedjul.new({
      :conditions => ["sked", "roster", "volunteer_task_type", "weekday"],
      :date_range_condition => "date",

      :block_method_name => "volunteer_events.date",
      :block_anchor => 'volunteer_shifts.date_anchor',
      :block_method_display => "volunteer_shifts.date_display",
      :block_start_time => "volunteer_shifts.weekdays.start_time",
      :block_end_time => "volunteer_shifts.weekdays.end_time",

      :left_unique_value => "volunteer_shifts.left_unique_value", # model
      :left_sort_value => "(coalesce(volunteer_task_types.description, volunteer_events.description)), volunteer_shifts.slot_number",
      :left_method_name => "volunteer_shifts.left_method_name",
      :left_table_name => "volunteer_shifts",

      :thing_start_time => "volunteer_shifts.start_time",
      :thing_end_time => "volunteer_shifts.end_time",
      :thing_table_name => "volunteer_shifts",
      :thing_description => "volunteer_shifts.shift_display",
      :thing_link_id => "volunteer_shifts.id",
      :thing_links => [[:edit, :popup], [:destroy, :confirm]] # TODO: impliment [:copy, :popup], that works across multiple events

      }, params)

    @skedj.find({:include => [:volunteer_task_type, :volunteer_event]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "assignments/index", :layout => :with_sidebar
    end
  end

  def edit
    vs = VolunteerShift.find(params[:id])
    redirect_to :controller => "volunteer_events", :id => vs.volunteer_event_id, :action => "edit"
  end

  def destroy
    vs = VolunteerShift.find(params[:id])
    vs.destroy

    redirect_skedj(request.env["HTTP_REFERER"], vs.date_anchor)
  end
end
