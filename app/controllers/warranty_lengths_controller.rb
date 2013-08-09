class WarrantyLengthsController < ApplicationController
  layout :with_sidebar

  protected

  before_filter :ensure_metadata
  def ensure_metadata
    @@rt_metadata ||= _parse_metadata_wo
    @rt_metadata = @@rt_metadata
  end
  public

  def index
    @warranty_lengths = WarrantyLength.find(:all)
  end

  def new
    @warranty_length = WarrantyLength.new
  end

  def edit
    @warranty_length = WarrantyLength.find(params[:id])
  end

  def create
    @warranty_length = WarrantyLength.new(params[:warranty_length])

    if @warranty_length.save
      flash[:notice] = 'WarrantyLength was successfully created.'
      redirect_to({:action => "index", :id => @warranty_length.id})
    else
      render :action => "new"
    end
  end

  def update
    @warranty_length = WarrantyLength.find(params[:id])

    if @warranty_length.update_attributes(params[:warranty_length])
      flash[:notice] = 'WarrantyLength was successfully updated.'
      redirect_to({:action => "index", :id => @warranty_length.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @warranty_length = WarrantyLength.find(params[:id])
    @warranty_length.destroy

    redirect_to({:action => "index"})
  end
end
