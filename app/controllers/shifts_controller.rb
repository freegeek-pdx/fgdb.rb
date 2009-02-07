class ShiftsController < ApplicationController
  layout "skedjulnator"
  before_filter :skedjulnator_role

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
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
    Shift.find(params[:id]).destroy
    redirect_to :action => 'view_weekly_schedule'
  end

  def view_weekly_schedule
    session["shift_return_to"] = "shifts"
    session["shift_return_action"] = "view_weekly_schedule"
    where_clause = "(NOT actual) AND "
    where_clause += "(shift_date IS NULL) AND "
    where_clause += "('#{Date.today}' BETWEEN shifts.effective_date AND shifts.ineffective_date OR shifts.ineffective_date IS NULL)"
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
      if @opts['limit_to_worker'] and @opts['limit_to_worker'] == '1'
        where_clause += ' AND shifts.worker_id = '
        where_clause += @opts['worker_id']
      end
      if @opts['limit_to_job'] and @opts['limit_to_job'] == '1'
        where_clause += ' AND shifts.job_id = '
        where_clause += @opts['job_id']
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
      in_clause = @root_sched.in_clause_family
    end
    where_clause += ' AND schedule_id IN ' + in_clause

    @shifts = Shift.find(:all, {
      :conditions => where_clause, 
      :select => 'shifts.*, workers.name', 
      :joins => 'LEFT JOIN workers ON shifts.worker_id = workers.id', 
      :order => 'weekday_id, workers.name, start_time'} 
    )
    render @view_weekly_schedule
  end

  def generate
    
    start_date = params[:date_range]['start_date']
    end_date = params[:date_range]['end_date']
    date_format='%Y-%m-%d'
    start = Date.strptime(start_date, date_format) 
    stop = Date.strptime(end_date, date_format) 

      # check to see what we will be overwriting:
      sql = "SELECT id FROM work_shifts WHERE shift_date BETWEEN '#{start.to_s}' AND '#{stop.to_s}' AND actual"
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
        holly = Holiday.find(:first, :conditions => ["holiday_date = ?", day])
        if holly
          # insert a holiday shift:
        else
          # check to see if the schedule displays on that
          #   weekday, if not then skip
          weekday_id = day.strftime( '%w' )
          weekday = Weekday.find(:first, :conditions => ["id = ?", weekday_id])
          if weekday.is_open
            # get standard shifts that match the day of week
            #   order by workers.name, start_time
            # ASSUMPTION: 
            #   either the weekday_id is null
            #   or the shift_date is null
            @root_sched = Schedule.find( :first, :conditions => ["? BETWEEN effective_date AND ineffective_date AND parent_id IS NULL", day] )
            in_clause = @root_sched.in_clause_family
            where_clause = <<WHERE
        (NOT actual) AND 
        ('#{day}' BETWEEN shifts.effective_date AND shifts.ineffective_date) AND
        ( 
          ( shifts.shift_date = '#{day}' ) 
            OR
          ( shifts.type IN ('StandardShift','Meeting') AND shifts.schedule_id IN #{in_clause} AND shifts.weekday_id = #{weekday_id} ) 
            OR
          ( shifts.type = 'Unavailability' AND shifts.weekday_id = #{weekday_id} ) 
        )
    
WHERE
            #logger.info 'qqq where_clause: ' + where_clause
            @shifts = Shift.find(:all, {
              :conditions => where_clause, 
              :select => 'shifts.*, workers.name', 
              :joins => 'LEFT JOIN workers ON shifts.worker_id = workers.id', 
              :order => 'workers.name, start_time, end_time'} 
            )
            @shifts.each do |@shift|
              case @shift[:type] 
                when 'Meeting'
                  #   check to see if its schedule prints this week
                  #     (repeats_every and repeats_on), if not then
                  #     skip
                  if @shift.schedule.which_week( day ) == @shift.schedule.repeats_on
                    #   create a new work shift from this standard shift
                    if (not @shift.shift_date) or @shift.shift_date == day
                      # get a list of all workers attending this
                      # meeting and loop through it
                      @shift.workers.each do |w|
                        # if worker is on vacation, don't save shift
                        v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
                        if not v
                          workshift = WorkShift.create_from_meeting( @shift, w, day )
                          # workshift.worker_id = w.id
                          workshift.save
                        end
                      end
                    end
                  end
                when 'StandardShift'
                  # check schedule for repeats_every / repeats_on logic
                  if @shift.schedule.which_week( day ) == @shift.schedule.repeats_on
                    # standard shifts always get saved (even if the worker can't work)
                    # create a new work_shift from the date and standard_shift
                    workshift = WorkShift.create_from_standard_shift( @shift, day )
                    if workshift
                      zero = Worker.find(:first, :conditions => 'id = 0')
                      w = @shift.worker 
                      v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
                      if v
                        # check to see if worker's vacation overlaps with
                        #   this shift, if so then set worker_id to 0
                        workshift.worker = zero 
                      end
                      if workshift.worker and  workshift.worker.effective_date and ( workshift.worker.effective_date > day or workshift.worker.ineffective_date < day )
                        # check to see if worker is no longer working 
                        #   (or hasn't started yet)
                        #   if so then set worker_id to 0
                        workshift.worker = zero 
                      end
                      if not w.is_available? workshift 
                        # check to see if worker is available for this shift,
                        #   if not then set worker_id to 0
                        workshift.worker = zero 
                      end
                      workshift.save
                    end
                  end
                when 'Unavailability'
                  # NOTE: don't check schedule, since it doesn't apply
                  # check for unavailability's repeats_every / repeats_on logic instead
                  if @shift.which_week( day ) == @shift.repeats_on
                    # if worker is on vacation anyway, don't save the shift
                    w = @shift.worker 
                    v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
                    if not v
                      workshift = WorkShift.create_from_unavailability( @shift, day )
                      workshift.save
                    end
                  end
              end
            end
          end
        end
        # next
      end
      redirect_to :action => 'list', :controller => 'work_shifts', :start_date => start, :end_date => stop
  end
end
