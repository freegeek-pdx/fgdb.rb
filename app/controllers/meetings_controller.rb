class MeetingsController < ApplicationController
  layout "skedjulnator"
  protected
  public

  before_filter :update_skedjulnator_access_time

  require_dependency 'shift'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @meetings = Meeting.paginate :order => 'shift_date DESC, weekday_id', :conditions => ["(shift_date IS NULL OR shift_date >= ?) AND (ineffective_date IS NULL OR ineffective_date >= ?) AND schedule_id = ?", Date.today, Date.today, Schedule.generate_from ? Schedule.generate_from.id : -1], :per_page => 30, :page => params[:page]
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
    @meeting.meeting_minders.each do |m|
      @meeting2.meeting_minders << m.clone
    end
    if @meeting2.save
      flash[:notice] = 'Meeting was successfully copied.'
      redirect_to :action => 'edit', :id => @meeting2.id
    else
      render :action => 'new'
    end
  end

  def replace
    @meeting = Meeting.find(params[:id])
    h = params["meeting_#{@meeting.id}"]
    @date = h ? h[:date] : nil
    @meeting2 = @meeting.clone
    @meeting2.workers = @meeting.workers
    @meeting.ineffective_date = @meeting2.effective_date = @date
    @meeting.save
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

    Shift.destroy_in_range(day, day, "work_shifts.meeting_id = #{@meeting.id}")
    Shift.generate(day, day, "shifts.id IN (#{@meeting.id})")

    redirect_to :action => 'list', :controller => 'work_shifts'
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
