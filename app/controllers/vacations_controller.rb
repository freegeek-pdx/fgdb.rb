class VacationsController < ApplicationController
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
    @vacations = Vacation.paginate :order => 'effective_date, ineffective_date', :conditions => ["ineffective_date >= ?", Date.today], :per_page => 20, :page => params[:page]
  end

  def full_list
    @vacations = Vacation.paginate :order => 'effective_date, ineffective_date', :per_page => 20, :page => params[:page]
  end

  def show
    @vacation = Vacation.find(params[:id])
  end

  def new
    @vacation = Vacation.new
  end

  def create
    @vacation = Vacation.new(params[:vacation])
    if @vacation.save
      flash[:notice] = 'Vacation was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def copy
    @vacation = Vacation.find(params[:id])
    @vacation2 = @vacation.clone
    if @vacation2.save
      flash[:notice] = 'Vacation was successfully copied.'
      redirect_to :action => 'edit', :id => @vacation2.id
    else
      render :action => 'new'
    end
  end

  def edit
    @vacation = Vacation.find(params[:id])
  end

  def update
    @vacation = Vacation.find(params[:id])
    if @vacation.update_attributes(params[:vacation])
      flash[:notice] = 'Vacation was successfully updated.'
      redirect_to :action => 'show', :id => @vacation
    else
      render :action => 'edit'
    end
  end

  def destroy
    Vacation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
