class UnavailabilitiesController < ApplicationController
  layout "skedjulnator"
  protected
  public
  require_dependency 'shift'
  def index
    list
    render :action => 'list'
  end

  before_filter :update_skedjulnator_access_time

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @unavailabilities = Unavailability.paginate :order => 'weekday_id, ineffective_date, end_time', :conditions => ["ineffective_date IS NULL OR ineffective_date >= ?", Date.today], :per_page => 20, :page => params[:page]
  end

  def full_list
    @unavailabilities = Unavailability.paginate :order => 'shift_date DESC, weekday_id', :per_page => 10, :page => params[:page]
  end

  def show
    @unavailability = Unavailability.find(params[:id])
  end

  def generate
    @unavailability = Unavailability.find(params[:id])
    # generates until the ineffective date or the last generate shift, whichever comes first
    max = WorkShift.maximum(:shift_date)
    max = [max, @unavailability.ineffective_date].select{|x| !x.nil?}.min
    # generates from today, or the effective date, whichever comes first
    min = Date.today
    min = [min, @unavailability.effective_date].select{|x| !x.nil?}.max
    # uses the min date as the max if the max is smaller than the min
    max = [min, max].max
    Shift.destroy_in_range(min, max, "work_shifts.shift_id = #{@unavailability.id}")
    Shift.generate(min, max, "shifts.id = #{@unavailability.id}")
    redirect_to :back
  end

  def new
    @unavailability = Unavailability.new
  end

  def create
    @unavailability = Unavailability.new(params[:unavailability])
    if @unavailability.save
      flash[:notice] = 'Unavailability was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def copy
    @unavailability = Unavailability.find(params[:id])
    @unavailability2 = @unavailability.clone
    if @unavailability2.save
      flash[:notice] = 'Unavailability was successfully copied.'
      redirect_to :action => 'edit', :id => @unavailability2.id
    else
      render :action => 'new'
    end
  end

  def edit
    @unavailability = Unavailability.find(params[:id])
  end

  def update
    @unavailability = Unavailability.find(params[:id])
    if @unavailability.update_attributes(params[:unavailability])
      flash[:notice] = 'Unavailability was successfully updated.'
      redirect_to :action => 'list', :id => @unavailability
    else
      render :action => 'edit'
    end
  end

  def destroy
    Unavailability.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
