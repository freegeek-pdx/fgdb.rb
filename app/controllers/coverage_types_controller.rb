class CoverageTypesController < ApplicationController
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
    @coverage_types = CoverageType.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @coverage_type = CoverageType.find(params[:id])
  end

  def new
    @coverage_type = CoverageType.new
  end

  def create
    @coverage_type = CoverageType.new(params[:coverage_type])
    if @coverage_type.save
      flash[:notice] = 'CoverageType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @coverage_type = CoverageType.find(params[:id])
  end

  def update
    @coverage_type = CoverageType.find(params[:id])
    if @coverage_type.update_attributes(params[:coverage_type])
      flash[:notice] = 'CoverageType was successfully updated.'
      redirect_to :action => 'show', :id => @coverage_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    CoverageType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
