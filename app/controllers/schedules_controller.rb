class SchedulesController < ApplicationController
  layout "skedjulnator"
  before_filter :skedjulnator_role

  def index
    list
    render :action => 'list'
  end

#  def index(id = params[:node])
#    respond_to do |format|
#      format.html # render static index.html.erb
#      format.json { render :json => Schedule.find_children(id) }
#    end
#  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @schedules = Schedule.paginate :per_page => 20, :page => params[:page]
  end

  def show
    @schedule = Schedule.find(params[:id])
  end

  def new
    @schedule = Schedule.new
  end

  def create
    @schedule = Schedule.new(params[:schedule])
    if @schedule.save
      flash[:notice] = 'Schedule was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def create_child(parent = Schedule.find( :first, :order => 'lft DESC', :conditions => 'parent_id IS NULL')
)
    @schedule = Schedule.new(params[:schedule])
    if @schedule.save
      @schedule.move_to_child_of(parent)
      flash[:notice] = 'Schedule was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @schedule = Schedule.find(params[:id])
  end

  def update
    @schedule = Schedule.find(params[:id])
    if @schedule.update_attributes(params[:schedule])
      flash[:notice] = 'Schedule was successfully updated.'
      redirect_to :action => 'show', :id => @schedule
    else
      render :action => 'edit'
    end
  end

  def destroy
    Schedule.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
