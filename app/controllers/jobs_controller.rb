class JobsController < ApplicationController
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
    @jobs = Job.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @job = Job.find(params[:id])
  end

  def new
    @job = Job.new
  end

  def create
    @job = Job.new(params[:job])
    if @job.save
      flash[:notice] = 'Job was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @job = Job.find(params[:id])
    session["shift_return_to"] = "jobs"
    session["shift_return_action"] = "edit"
    session["shift_return_id"] = @job.id 
  end

  def update
    @job = Job.find(params[:id])
    if !params[:job][:worker_ids]
      @job.workers.clear
    end
    if @job.update_attributes(params[:job])
      flash[:notice] = 'Job was successfully updated.'
      redirect_to :action => 'show', :id => @job
    else
      render :action => 'edit'
    end
  end

  def destroy
    Job.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
