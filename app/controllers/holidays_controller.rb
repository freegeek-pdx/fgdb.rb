class HolidaysController < ApplicationController
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
