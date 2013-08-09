class ResourcesVolunteerDefaultEventsController < ApplicationController
  protected
  public

  layout :with_sidebar

  helper :skedjul

  def generate
    do_volskedj_generate('resources_volunteer_events')
  end

  def index
    if params[:conditions]
    @skedj = Skedjul.new({
      :generate_param_key => "date_range",
      :generate_conditions => ["sked", "roster"],
      :conditions => ["weekday", "sked", "roster"],

      :block_method_name => "resources_volunteer_default_events.volunteer_default_events.weekday_id",
      :block_method_display => "volunteer_default_events.weekdays.name",
      :block_start_time => "volunteer_default_events.weekdays.start_time",
      :block_end_time => "volunteer_default_events.weekdays.end_time",

      :left_unique_value => "resources_volunteer_default_events.resources.name", # model
      :left_method_name => "resources_volunteer_default_events.resources.name",
      :left_sort_value => "resources_volunteer_default_events.resources.name",
      :left_table_name => "resources",
      :left_link_action => "edit",
      :left_link_id => "resources.id",

      :thing_start_time => "resources_volunteer_default_events.start_time",
      :thing_end_time => "resources_volunteer_default_events.end_time",
      :thing_table_name => "resources_volunteer_default_events",
      :thing_description => "resources_volunteer_default_events.time_range_s",
      :thing_link_id => "resources_volunteer_default_events.id",
      :thing_links => [[:edit, :popup], [:destroy, :confirm]]

      }, params)

    @skedj.find({:include => [:resource => [], :volunteer_default_event => [:weekday]]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "assignments/index", :layout => :with_sidebar
    end
  end

  def edit
    @volunteer_default_shift = ResourcesVolunteerDefaultEvent.find(params[:id])
    redirect_to({:controller => "volunteer_default_events", :action => "edit", :id => @volunteer_default_shift.volunteer_default_event_id})
  end

  def destroy
    @volunteer_default_shift = ResourcesVolunteerDefaultEvent.find(params[:id])
    @volunteer_default_shift.destroy

    redirect_skedj(request.env["HTTP_REFERER"], @volunteer_default_shift.volunteer_default_event.weekday.name)
  end
end
