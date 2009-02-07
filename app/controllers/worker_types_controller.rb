class WorkerTypesController < ApplicationController
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
    @worker_types = WorkerType.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @worker_type = WorkerType.find(params[:id])
  end

  def new
    @worker_type = WorkerType.new
  end

  def create
    @worker_type = WorkerType.new(params[:worker_type])
    if @worker_type.save
      flash[:notice] = 'WorkerType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @worker_type = WorkerType.find(params[:id])
  end

  def update
    @worker_type = WorkerType.find(params[:id])
    if @worker_type.update_attributes(params[:worker_type])
      flash[:notice] = 'WorkerType was successfully updated.'
      redirect_to :action => 'show', :id => @worker_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    WorkerType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
