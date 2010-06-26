class MeetingsController < ApplicationController
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
    @meetings = Meeting.paginate :order => 'shift_date DESC, weekday_id', :conditions => ["(shift_date IS NULL OR shift_date >= ?) AND ineffective_date >= ?", Date.today, Date.today], :per_page => 30, :page => params[:page]
  end

  def full_list
    @meetings = Meeting.paginate :order => 'shift_date DESC, weekday_id', :per_page => 20, :page => params[:page]
  end

  def show
    @meeting = Meeting.find(params[:id])
  end

  def new
    @meeting = Meeting.new
  end

  def create
    @meeting = Meeting.new(params[:meeting])
    if @meeting.save
      flash[:notice] = 'Meeting was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def copy
    @meeting = Meeting.find(params[:id])
    @meeting2 = @meeting.clone
    @meeting2.workers = @meeting.workers
    if @meeting2.save
      flash[:notice] = 'Meeting was successfully copied.'
      redirect_to :action => 'edit', :id => @meeting2.id
    else
      render :action => 'new'
    end
  end

  def generate
    # this is intended to be called from meetings list on only
    # those meetings with actual dates. this means we don't need
    # to regenerate the whole day (which may have customizations)
    # just to create an actual one off meeting on the schedule
    @meeting = Meeting.find(params[:id])
    day = @meeting.shift_date
    # check to see what we will be overwriting:
    sql = "SELECT id FROM work_shifts WHERE meeting_id = #{@meeting.id} "
    remove = WorkShift.find_by_sql( sql )
    if remove.size > 0
      warning = 'Delete all shifts for this meeting?'
      in_clause = Array.new
      remove.each do |shift| 
        in_clause << shift.id
      end
      WorkShift.delete_all "id IN (#{in_clause.join(',')})"
    end
    # check to see if it's a holiday, if so then skip
    holly = Holiday.is_holiday?(day)
    if not holly
      # check to see if the schedule displays on that
      #   weekday, if not then skip
      weekday_id = day.strftime( '%w' )
      weekday = Weekday.find(:first, :conditions => ["id = ?", weekday_id])
      # get a list of all workers attending this
      # meeting and loop through it
      @meeting.workers.each do |w|
        # if worker is on vacation, don't save shift
        v = Vacation.find(:first, :conditions => ["worker_id = ? AND ? BETWEEN effective_date AND ineffective_date", w.id, day])
        if not v
          workshift = WorkShift.create_from_meeting( @meeting, w, day )
          workshift.save
        end
      end
      redirect_to :action => 'list', :controller => 'work_shifts'
    end
  end

  def edit
    @meeting = Meeting.find(params[:id])
  end

  def update
    # NOTE: find() brings back '2000-01-01' where there should
    # be a null date if a date field is left blank. this is fixed with a kludge in
    # vendor/plugins/dhtml-calendar/lib/extensions/active_record.rb
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(params[:meeting])
      flash[:notice] = 'Meeting was successfully updated.'
      redirect_to :action => 'show', :id => @meeting
    else
      render :action => 'edit'
    end
  end

  def destroy
    Meeting.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
