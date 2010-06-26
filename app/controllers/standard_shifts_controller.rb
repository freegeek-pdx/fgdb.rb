class StandardShiftsController < ApplicationController
  layout "skedjulnator"
  before_filter :skedjulnator_role

  require_dependency 'shift'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  def list
    session["shift_return_to"] = "standard_shifts"
    session["shift_return_action"] = "list"
    if params[:filter_criteria]
      @opts = params[:filter_criteria]
      @root_sched = Schedule.find( :first, :conditions => ["id = ?", @opts['schedule_id']])
      if  @opts['which_way'] == 'Family'
        in_clause = @root_sched.in_clause_family
      else
        if  @opts['which_way'] == 'Solo'
          in_clause = @root_sched.in_clause_solo
        else
          in_clause = @root_sched.in_clause_root_plus
        end
      end
      where_clause1 = ''
      where_clause2 = ''
      if @opts['limit_to_worker'] and @opts['limit_to_worker'] == '1'
        where_clause1 += ' AND standard_shifts.worker_id = '
        where_clause1 += @opts['worker_id']
        where_clause2 += ' AND meetings_workers.worker_id = '
        where_clause2 += @opts['worker_id']
      end
      if @opts['limit_to_job'] and @opts['limit_to_job'] == '1'
        where_clause1 += ' AND standard_shifts.job_id = '
        where_clause1 += @opts['job_id']
        where_clause2 = ' AND standard_shifts.job_id IS NOT NULL '
      end
    else
      @root_sched = Schedule.find( :first, :order => 'id', :conditions => 'parent_id IS NULL')
      @opts = { 
        'schedule_id' => @root_sched.id, 
        'which_way' => 'Family', 
        'limit_to_worker' => '0', 
        'limit_to_job' => '0', 
        'worker_id' => 0, 
        'job_id' => 0, 
        'presentation_mode' => 'Edit' }
      in_clause = @root_sched.in_clause_root_plus
      where_clause1 = ''
      where_clause2 = ''
    end

    sql = <<SQL
SELECT 
    standard_shifts.weekday_id, 
    workers.name,
    standard_shifts.start_time, 
    standard_shifts.end_time, 
    standard_shifts.id, 
    standard_shifts.splitable, 
    standard_shifts.mergeable, 
    standard_shifts.resizable,
    standard_shifts.coverage_type_id, 
    standard_shifts.job_id, 
    standard_shifts.schedule_id, 
    standard_shifts.worker_id, 
    standard_shifts.meeting_id 
    FROM standard_shifts
    LEFT JOIN workers ON standard_shifts.worker_id = workers.id 
    WHERE standard_shifts.schedule_id IN #{in_clause}
    AND standard_shifts.meeting_id IS NULL #{where_clause1}
UNION
SELECT 
    meetings.weekday_id, 
    workers.name,
    meetings.start_time, 
    meetings.end_time, 
    standard_shifts.id,
    false, 
    false, 
    false,
    meetings.coverage_type_id, 
    standard_shifts.job_id, 
    meetings.schedule_id,
    meetings_workers.worker_id,
    standard_shifts.meeting_id 
    FROM meetings 
    LEFT JOIN standard_shifts ON meetings.id = standard_shifts.meeting_id
    LEFT JOIN meetings_workers ON standard_shifts.meeting_id = meetings_workers.meeting_id 
    LEFT JOIN workers ON meetings_workers.worker_id = workers.id 
    WHERE meetings.schedule_id IN #{in_clause}
    AND standard_shifts.meeting_id IS NOT NULL #{where_clause2}
ORDER BY 1, 2, 3, 4
SQL

    @standard_shifts = StandardShift.find_by_sql( sql )
    render @list
  end

  def show
    @standard_shift = StandardShift.find(params[:id])
  end

  def new
    @standard_shift = StandardShift.new
    if params[:schedule_id]
      @standard_shift.schedule_id = params[:schedule_id]
    end
  end

  def generate
    start = Date.civil(params[:generate_schedule][:"start_date(1i)"].to_i,params[:generate_schedule][:"start_date(2i)"].to_i,params[:generate_schedule][:"start_date(3i)"].to_i)
    stop = Date.civil(params[:generate_schedule][:"end_date(1i)"].to_i,params[:generate_schedule][:"end_date(2i)"].to_i,params[:generate_schedule][:"end_date(3i)"].to_i)

      # check to see what we will be overwriting:
      sql = "SELECT id FROM work_shifts WHERE shift_date BETWEEN '#{start.to_s}' AND '#{stop.to_s}'"
      remove = WorkShift.find_by_sql( sql )
      if remove.size > 0
        warning = 'Delete all shifts between #{start.to_s} and #{stop.to_s} (#{remove.size} shifts)?'
        in_clause = Array.new
        remove.each do |shift| 
          in_clause << shift.id
        end
        WorkShift.delete_all "id IN (#{in_clause.join(',')})"
      end
      (start..stop).each do |day|
        # check to see if it's a holiday, if so then skip
        holly = Holiday.is_holiday?(day)
        if holly
          # insert a holiday shift:
        else
          # check to see if the schedule displays on that
          #   weekday, if not then skip
          weekday_id = day.strftime( '%w' )
          weekday = Weekday.find(:first, :conditions => ["id = ?", weekday_id])
            # get standard shifts that match the day of week
            #   order by workers.name, start_time
            @root_sched = Schedule.find( :first, :conditions => ["? BETWEEN effective_date AND ineffective_date ", day] )
            in_clause = @root_sched.in_clause_family
            sql = <<SQL
SELECT 
    workers.name,
    standard_shifts.start_time, 
    standard_shifts.end_time, 
    standard_shifts.shift_date, 
    standard_shifts.id, 
    standard_shifts.splitable, 
    standard_shifts.mergeable, 
    standard_shifts.resizable,
    standard_shifts.job_id, 
    standard_shifts.schedule_id, 
    standard_shifts.worker_id, 
    standard_shifts.meeting_id, 
    standard_shifts.weekday_id 
    FROM standard_shifts
    LEFT JOIN workers ON standard_shifts.worker_id = workers.id 
    WHERE standard_shifts.schedule_id IN #{in_clause} 
    AND standard_shifts.weekday_id = #{weekday_id}
    AND standard_shifts.meeting_id IS NULL
UNION
SELECT 
    workers.name,
    meetings.start_time, 
    meetings.end_time, 
    meetings.meeting_date, 
    meetings.id,
    meetings.splitable, 
    meetings.mergeable, 
    meetings.resizable,
    NULL, 
    meetings.schedule_id,
    meetings_workers.worker_id,
    meetings.id, 
    meetings.weekday_id 
    FROM meetings 
    LEFT JOIN meetings_workers ON meetings.id = meetings_workers.meeting_id 
    LEFT JOIN workers ON meetings_workers.worker_id = workers.id 
    WHERE meetings.schedule_id IN #{in_clause}
    AND meetings.weekday_id = #{weekday_id}
    AND '#{day}' BETWEEN meetings.effective_date AND meetings.ineffective_date
ORDER BY 1, 2, 3
SQL
            @standard_shifts = StandardShift.find_by_sql( sql )
            @standard_shifts.each do |@shift|
              # for each shift:
              #   check to see if its schedule prints this week
              #     (repeats_every and repeats_on), if not then
              #     skip
              if @shift.schedule.which_week( day ) == @shift.schedule.repeats_on
                #   create a new work shift from this standard
                #     shift
                if @shift.meeting_id and @shift.meeting_id > 0
                  if (not @shift.shift_date) or @shift.shift_date == day
                    workshift = WorkShift.create_from_meeting( @shift, day )
                  end
                else
                  workshift = WorkShift.create_from_standard_shift( @shift, day )
                end
                #   check to see if worker's vacation overlaps with
                #     this shift, if so then set worker_id to 0
                w = @shift.worker 
                v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
                if workshift and v
                  workshift.worker = Worker.find(:first, :conditions => 'id = 0')
                end
                #   check to see if worker is available for this shift,
                #     if not then set worker_id to 0
                if workshift and w.is_available? workshift 
                  #   create a new work_shift from the date and
                  #     standard_shift
                  workshift.save
                end
            end
          end
        end
        # next
      end
      redirect_to :action => 'list', :controller => 'work_shifts', :start_date => start, :end_date => stop
  end

  def create
    @standard_shift = StandardShift.new(params[:standard_shift])
    if @standard_shift.save
      flash[:notice] = 'StandardShift was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def copy
    @standard_shift = StandardShift.find(params[:id])
    @standard_shift2 = @standard_shift.clone
    if @standard_shift2.save
      flash[:notice] = 'StandardShift was successfully copied.'
      redirect_to :action => 'edit', :id => @standard_shift2.id
    else
      render :action => 'new'
    end
  end

  def edit
    @standard_shift = StandardShift.find(params[:id])
  end

  def update
    @standard_shift = StandardShift.find(params[:id])
    if @standard_shift.update_attributes(params[:standard_shift])
      flash[:notice] = 'StandardShift was successfully updated.'
      # redirect to list view, the id might be useful for
      # positioning us on the page somehow?
      if session["shift_return_to"] 
        redirect_to :controller => session["shift_return_to"], :action => session["shift_return_action"], :id => session["shift_return_id"]
      else
        redirect_to :action => 'list', :id => @standard_shift
      end
    else
      render :action => 'edit'
    end
  end

  def destroy
    StandardShift.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
