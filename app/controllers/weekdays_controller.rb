class WeekdaysController < ApplicationController
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
    @weekdays = Weekday.paginate :order => 'id', :per_page => 20, :page => params[:page]
  end

  def show
    @weekday = Weekday.find(params[:id])
  end

  def new
    @weekday = Weekday.new
  end

  def create
    @weekday = Weekday.new(params[:weekday])
    if @weekday.save
      flash[:notice] = 'Weekday was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @weekday = Weekday.find(params[:id])
  end

  def update
    @weekday = Weekday.find(params[:id])
    if @weekday.update_attributes(params[:weekday])
      flash[:notice] = 'Weekday was successfully updated.'
      redirect_to :action => 'show', :id => @weekday
    else
      render :action => 'edit'
    end
  end

  def destroy
    Weekday.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
