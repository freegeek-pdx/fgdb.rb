class ResourcesVolunteerEventsController < ApplicationController
  protected
  public

  layout :with_sidebar

  helper :skedjul

  def index
    if params[:conditions]
    @skedj = Skedjul.new({
      :conditions => ["sked", "roster"],
      :date_range_condition => "date",

      :block_method_name => "volunteer_events.date",
      :block_anchor => 'resources_volunteer_events.date_anchor',
      :block_method_display => "resources_volunteer_events.date_display",
      :block_start_time => "resources_volunteer_events.weekdays.start_time",
      :block_end_time => "resources_volunteer_events.weekdays.end_time",

      :left_unique_value => "resources.id", # model
      :left_sort_value => "resources.name",
      :left_method_name => "resources.name",
      :left_table_name => "resources",
      :left_link_action => "edit",
      :left_link_id => "resources.id",

      :thing_start_time => "resources_volunteer_events.start_time",
      :thing_end_time => "resources_volunteer_events.end_time",
      :thing_table_name => "resources_volunteer_events",
      :thing_description => "resources_volunteer_events.display",
      :thing_link_id => "resources_volunteer_events.id",
      :thing_links => [[:edit, :popup], [:destroy, :confirm]] # TODO: impliment [:copy, :popup], that works across multiple events

      }, params)

    @skedj.find({:include => [:resource, :volunteer_event]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "assignments/index", :layout => :with_sidebar
    end
  end

  def edit
    vs = ResourcesVolunteerEvent.find(params[:id])
    redirect_to :controller => "volunteer_events", :id => vs.volunteer_event_id, :action => "edit"
  end

  def destroy
    vs = ResourcesVolunteerEvent.find(params[:id])
    vs.destroy

    redirect_skedj(request.env["HTTP_REFERER"], vs.date_anchor)
  end
end
