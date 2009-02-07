class FrequencyTypesController < ApplicationController
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
    @frequency_types = FrequencyType.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @frequency_type = FrequencyType.find(params[:id])
  end

  def new
    @frequency_type = FrequencyType.new
  end

  def create
    @frequency_type = FrequencyType.new(params[:frequency_type])
    if @frequency_type.save
      flash[:notice] = 'FrequencyType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @frequency_type = FrequencyType.find(params[:id])
  end

  def update
    @frequency_type = FrequencyType.find(params[:id])
    if @frequency_type.update_attributes(params[:frequency_type])
      flash[:notice] = 'FrequencyType was successfully updated.'
      redirect_to :action => 'show', :id => @frequency_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    FrequencyType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
