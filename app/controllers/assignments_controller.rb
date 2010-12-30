class AssignmentsController < ApplicationController
  before_filter :authorized_only
  protected
  def authorized_only
    requires_role('VOLUNTEER_MANAGER')
  end
  public

  layout :with_sidebar

  helper :skedjul

  def index
    if params[:conditions]
    @skedj = Skedjul.new({
      :conditions => ['contact', "sked", "roster", "volunteer_task_type"],
      :date_range_condition => "date",

      :block_method_name => "volunteer_shifts.date",
      :block_method_display => "volunteer_shifts.date_display",
      :block_start_time => "volunteer_shifts.weekdays.start_time",
      :block_end_time => "volunteer_shifts.weekdays.end_time",
      :default_view => "by_slot",

                           :views => {
                             :by_slot =>
                             { :left_unique_value => "volunteer_shifts.description_and_slot", # model
                               :left_method_name => "volunteer_shifts.volunteer_task_types.description, volunteer_shifts.slot_number",
                               :left_table_name => "volunteer_shifts",
                               :left_link_action => "assign",
                               :left_link_id => "volunteer_shifts.description_and_slot",

                               :thing_start_time => "assignments.start_time",
                               :thing_end_time => "assignments.end_time",
                               :thing_table_name => "assignments",
                               :thing_description => "display_name",
                               :thing_link_id => "assignments.id",
                               :thing_links => [[:edit, :popup], [:destroy, :confirm, :contact_id]],
                             },

                             :by_worker =>
                             { :left_unique_value => "assignments.contact_id",
                               :left_sort_value => "assignments.contact_id",
                               :left_method_name => "assignments.contact_display",
                               :left_table_name => "contacts",
                               :left_link_action => "assignments",
                               :left_link_id => "contacts.id",

                               :thing_start_time => "assignments.start_time",
                               :thing_end_time => "assignments.end_time",
                               :thing_table_name => "assignments",
                               :thing_description => "volunteer_shifts.volunteer_task_types.description, volunteer_shifts.slot_number",
                               :thing_link_id => "assignments.id",
                               :thing_links => [[:edit, :popup], [:destroy, :confirm, :contact_id]],
                             }
                           },

      }, params)

    @opts = @skedj.opts
    @conditions = @skedj.conditions

    @skedj.find({:conditions => @skedj.where_clause, :include => [:contact => [], :volunteer_shift => [:volunteer_task_type]]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "index",  :layout => :with_sidebar
    end
  end

  def show
    @assignment = Assignment.find(params[:id])
  end

  def edit
    @assignment = Assignment.find(params[:id])
  end

  def create
    @assignment = Assignment.new(params[:assignment])

    if @assignment.save
      flash[:notice] = 'Assignment was successfully created.'
      redirect_to({:action => "index", :id => @assignment.id})
    else
      render :action => "new"
    end
  end

  def update
    @assignment = Assignment.find(params[:id])

    if @assignment.update_attributes(params[:assignment])
      flash[:notice] = 'Assignment was successfully updated.'
      redirect_to({:action => "index", :id => @assignment.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @assignment = Assignment.find(params[:id])
    @assignment.destroy

    redirect_to({:action => "index"})
  end
end