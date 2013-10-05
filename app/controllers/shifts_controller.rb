class ShiftsController < ApplicationController
  layout "skedjulnator"
  protected
  before_filter :enable_multi
  def enable_multi
    @multi_enabled = true
  end
  public

  def edit_footnote
    super
  end

  def save_footnote
    super
  end

  before_filter :update_skedjulnator_access_time

  def find_problems
    @weeks = [Weekday.find_by_name("Sunday")].map(&:id)
    @schedule = Schedule.find_by_id(params[:schedule_id])
    if @schedule
      do_find_problems_report(Shift, "weekday_id", @weeks, @weeks + [Weekday.find_by_name("Saturday")].map(&:id), "s", @schedule.id)
    else
      redirect_to :action => "view_weekly_schedule"
    end
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @shifts = Shift.paginate :order => 'weekday_id, worker_id, start_time', :per_page => 10, :page => params[:page]
  end

  def show
    @shift = Shift.find(params[:id])
  end

  def new
    @shift = Shift.new
  end

  def create
    @shift = Shift.new(params[:shift])
    if @shift.save
      flash[:notice] = 'Shift was successfully created.'
      redirect_to :action => 'view_weekly_schedule'
    else
      render :action => 'new'
    end
  end

  def copy
    @shift = Shift.find(params[:id])
    @shift2 = @shift.clone
    if @shift2.save
      flash[:notice] = 'Shift was successfully copied.'
      redirect_to :action => 'edit', :id => @shift2.id
    else
      render :action => 'new'
    end
  end

  def edit
    @shift = Shift.find(params[:id])
  end

  def update
    @shift = Shift.find(params[:id])
    if @shift.update_attributes(params[:shift])
      flash[:notice] = 'Shift was successfully updated.'
      redirect_to :action => 'show', :id => @shift
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      Shift.find(params[:id]).destroy
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "That shift is already gone."
    end

    redirect_to :action => 'view_weekly_schedule'
  end

  helper :skedjul

  def view_weekly_schedule
    session["shift_return_to"] = "shifts"
    session["shift_return_action"] = "view_weekly_schedule"

    @skedj = Skedjul.new({
      :generate_param_key => "date_range",
                           :generate_gen_sched_form_controller => "work_shifts",
                           :forced_condition => "schedule",
                           :conditions => ["job", "worker", "shift_type"],

      :default_view => "by_worker",
                           :views => {
                             :by_job => {
      :left_unique_value => "job_id",
      :left_sort_value => "jobs.name",
                               :left_method_name => "name_part",
      :left_table_name => "jobs",
      :thing_description => "display_worker_skedj",

                             },
                             :by_worker => {
      :left_unique_value => "worker_id",
      :left_method_name => "workers.name",
      :left_table_name => "workers",
      :thing_description => "display_name_skedj",
      :left_link_action => "edit",
      :left_link_id => "workers.id",

                             }
                           },

      :block_method_name => "shifts.weekday_id",
      :block_method_display => "weekdays.name",
      :block_start_time => "weekdays.start_time",
      :block_end_time => "weekdays.end_time",

      :thing_start_time => "shifts.start_time",
      :thing_end_time => "shifts.end_time",
      :thing_table_name => "shifts",
      :thing_link_id => "shifts.id",
      :thing_links => [[:copy, :popup, :has_copy], [:edit, :popup], [:destroy, :confirm]]

      }, params)

    @skedj.find({:include => [:weekday, :job, :worker, :schedule]})
  end

  def generate
    start_date = params[:date_range]['start_date']
    end_date = params[:date_range]['end_date']
    date_format='%Y-%m-%d'
    start = Date.strptime(start_date, date_format) 
    stop = Date.strptime(end_date, date_format) 

    Shift.destroy_in_range(start, stop)
    Shift.generate(start, stop, "proposed = 'f' AND schedule_id IN #{Schedule.generate_from.in_clause}")

      redirect_to :action => 'list', :controller => 'work_shifts', :start_date => start, :end_date => stop
  end
end
