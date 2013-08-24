class ResourcesController < ApplicationController
  protected
  public

  layout :with_sidebar

  def index
    @resources = Resource.find(:all)
  end

  def show
    @resource = Resource.find(params[:id])
  end

  def new
    @resource = Resource.new
  end

  def edit
    @resource = Resource.find(params[:id])
  end

  def create
    @resource = Resource.new(params[:resource])

    if @resource.save
      flash[:notice] = 'Resource was successfully created.'
      redirect_to({:action => "show", :id => @resource.id})
    else
      render :action => "new"
    end
  end

  def update
    @resource = Resource.find(params[:id])

    if @resource.update_attributes(params[:resource])
      flash[:notice] = 'Resource was successfully updated.'
      redirect_to({:action => "show", :id => @resource.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @resource = Resource.find(params[:id])
    @resource.destroy

    redirect_to({:action => "index"})
  end
end
