class HolidaysController < ApplicationController
  layout "skedjulnator"
  protected
  before_filter :update_skedjulnator_access_time, :except => [:is_holiday, :display, :show_display]
  public

  def display
    params[:start_date] = Date.today.to_s
    show_display
  end

  def show_display
    mstart = params[:start_date]
    mend = params[:end_date]
    mstart = Date.parse(mstart) if mstart
    mend = Date.parse(mend) if mend
    @range_to_s = (mstart ? mstart.to_s : "the beginning of time") + " to " + (mend ? mend.to_s : "the end of time")
    cond_str = 'schedule_id = ? AND is_all_day = ?'
    cond_opts = [Schedule.generate_from ? Schedule.generate_from.id : -1, true]
    if mstart
      cond_str += ' AND holiday_date >= ?'
      cond_opts << mstart
    end
    if mend
      cond_str += ' AND holiday_date <= ?'
      cond_opts << mend
    end
    cond_opts.unshift(cond_str)
    @holidays = Holiday.find(:all, :conditions => cond_opts).sort_by(&:holiday_date)
    render :action => 'display'
  end

  def is_holiday # used by meetme
    d = nil
    begin
      d = Date.parse(params[:date])
    end
    if d
      render :text => Holiday.is_holiday?(d)
    else
      render :text => "couldn't parse 'date' parameter"
    end
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @holidays = Holiday.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @holiday = Holiday.find(params[:id])
  end

  def new
    @holiday = Holiday.new
  end

  def create
    @holiday = Holiday.new(params[:holiday])
    if @holiday.save
      flash[:notice] = 'Holiday was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @holiday = Holiday.find(params[:id])
  end

  def update
    @holiday = Holiday.find(params[:id])
    if @holiday.update_attributes(params[:holiday])
      flash[:notice] = 'Holiday was successfully updated.'
      redirect_to :action => 'show', :id => @holiday
    else
      render :action => 'edit'
    end
  end

  def destroy
    Holiday.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
