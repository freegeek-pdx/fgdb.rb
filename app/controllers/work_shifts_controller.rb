class WorkShiftsController < ApplicationController
  layout "skedjulnator"

  def perpetual_meetings_publish
    @readonly = true
    perpetual_meetings
    render :action => 'perpetual_meetings'
  end

  def perpetual_meetings
    @meetings = Meeting.perpetual.effective_in_range(Date.today, Date.today + 30).generated
  end

  protected
  before_filter :enable_multi
  def enable_multi
    @multi_enabled = true
  end

  before_filter :update_skedjulnator_access_time, :except => [:staffsched, :staffsched_rolled_out, :staffsched_month, :perpetual_meetings, :staffsched_publish, :perpetual_meetings_publish]

  public

  def edit_footnote
    super
  end

  def save_footnote
    super
  end

  def update_rollout_date
    Default["staffsched_rollout_until"] = params[:date]
    Notifier.deliver_text_report('scheduler_reports_to', "Schedule rolled out to #{params[:date]}", "The schedule rollout date was changed to #{params[:date]} by #{Thread.current['user'].to_s} at #{Time.now.strftime("%D %T")}.")
    redirect_to :back
  end

  def find_problems
   begin
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])
    rescue
      redirect_to :action => "index"
      return
    end
    @disp_end_date = @end_date
    max_end = WorkShift.maximum('shift_date')
    @end_date = max_end if @end_date > max_end and max_end > @start_date
    w_start = @start_date
    while w_start.wday != 1
      w_start -= 1
    end
    w_end = @end_date
    while w_start.wday != 1
      w_start -= 1
    end
    @weeks = (w_start..w_end).to_a.select{|x| x.wday == 1}
    do_find_problems_report(WorkShift, "shift_date", @weeks, [@start_date, @end_date])
  end
  protected

  public

  def index
    list
    render :action => 'list'
  end

  def staffsched_publish
    params["opts"] = {:presentation_mode => "Preview"}
    @end_date = Default["staffsched_rollout_until"]
    staffsched
  end

  def staffsched_rolled_out
    @end_date = Default["staffsched_rollout_until"]
    staffsched
  end

  def staffsched_month
    @end_date = (Date.today + 30).to_s
    staffsched
  end

  def staffsched
    @readonly = true
    @end_date ||= Date.today.to_s
    @vacations = Vacation.find(:all, :order => 'effective_date, ineffective_date', :conditions => ["ineffective_date >= ?", Date.today])
    params["conditions"] ||= {:shift_date_enabled => "true", :shift_date_end_date => @end_date, :shift_date_start_date => Date.today.to_s, }
    params["opts"] ||= {:presentation_mode => "Display"}

    list
    render :action => 'list'
  end

  helper :skedjul

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update ], # TODO: destroy should be in this list but the skedjul_links thing needs support for :post
         :redirect_to => { :action => :list }

  def list
    session["shift_return_to"] = "work_shifts"
    session["shift_return_action"] = "list"

    @skedj = Skedjul.new({
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
      :left_extra_link_actions => ["absent", "vacation"],
      :left_extra_link_confirm => "Are you sure you want to remove them from the schedule?",
      :left_link_action => "edit",
      :left_link_id => "workers.id",
                             }
                           },

      :conditions => ["worker", "job", "shift_type"],
      :date_range_condition => "shift_date",
      :rollout_default_name => "staffsched_rollout_until",
      :rollout_default_action => "update_rollout_date",

      :block_method_name => "work_shifts.shift_date",
      :block_method_display => "work_shifts.shift_date_display",
      :block_start_time => "weekdays.start_time",
      :block_end_time => "weekdays.end_time",

      :thing_start_time => "work_shifts.start_time",
      :thing_end_time => "work_shifts.end_time",
      :thing_table_name => "work_shifts",
      :thing_description => "display_name_skedj",
      :thing_link_id => "work_shifts.id",
      :thing_links => [[:copy, :popup], [:edit, :popup], [:destroy, :confirm]]

      }, params)

    @skedj.find({:include => [:job, :worker, :weekday]})
  end

  def absent
    w = Worker.find_by_id(params[:id])
    d = nil
    begin
      d = Date.parse(params[:date])
    rescue
    end
    if w and d
      w.work_shifts_for_day(d).each(&:on_vacation)
      WorkShiftFootnote.add_to_footnote(d, "#{w.name} is out.")
    end
    redirect_to :action => "list"
  end

  def vacation
    w = Worker.find_by_id(params[:id])
    d = nil
    begin
      d = Date.parse(params[:date])
    rescue
    end
    if w and d
      v = Vacation.new(:effective_date => d, :ineffective_date => d, :worker => w, :is_all_day => true)
      v.save!
      v.generate
    end
    redirect_to :action => "list"
  end

  def show
    @work_shift = WorkShift.find(params[:id])
  end

  def new
    @work_shift = WorkShift.new
  end

  def create
    @work_shift = WorkShift.new(params[:work_shift])
    if @work_shift.save
      flash[:notice] = 'WorkShift was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def copy
    @work_shift = WorkShift.find(params[:id])
    @work_shift2 = @work_shift.clone
    if @work_shift2.save
      flash[:notice] = 'WorkShift was successfully copied.'
      redirect_to :action => 'edit', :id => @work_shift2.id
    else
      render :action => 'new'
    end
  end

  def edit
    @work_shift = WorkShift.find(params[:id])
  end

  def update
    @work_shift = WorkShift.find(params[:id])
    if @work_shift.update_attributes(params[:work_shift])
      flash[:notice] = 'WorkShift was successfully updated.'
      if session["shift_return_to"] 
        redirect_to :controller => session["shift_return_to"], :action => session["shift_return_action"], :id => session["shift_return_id"]
      else
        redirect_to :action => 'list', :id => @work_shift
      end
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      WorkShift.find(params[:id]).destroy
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "That work shift is already gone."
    end
    redirect_to :action => 'list'
  end
end
