class StorePricingsController < ApplicationController
  layout :with_sidebar

  def index
    @store_pricings = StorePricing.find(:all)
    @store_pricing = StorePricing.new
  end

  def search
    if params[:store_pricing]
      @store_pricing = StorePricing.find_by_barcode(params[:store_pricing][:barcode])
      if @store_pricing
        render :action => "edit"
      else
        flash[:error] = "Store pricing for that barcode was not found"
        redirect_to :action => "index"
      end
    else
      redirect_to :action => "index"
    end
  end

  def new
    @store_pricing = StorePricing.new(params[:store_pricing])
    if @store_pricing.system && @store_pricing.system.last_spec_sheet && @store_pricing.system.last_spec_sheet.type
      @store_pricing.gizmo_type = @store_pricing.system.last_spec_sheet.type.gizmo_type
    end
    if @store_pricing.system && @store_pricing.gizmo_type.nil?
      @store_pricing.gizmo_type = GizmoType.find_by_name('system')
    end
    if @store_pricing.system_id && @store_pricing.system.nil?
      @store_pricing.system_id = nil
    end
  end

  def create
    @store_pricing = StorePricing.new(params[:store_pricing])

    if @store_pricing.save
      flash[:notice] = 'StorePricing was successfully created.'
      redirect_to({:action => "search", :store_pricing => {:barcode => @store_pricing.barcode}})
    else
      render :action => "new"
    end
  end

  def update
    @store_pricing = StorePricing.find(params[:id])

    if @store_pricing.update_attributes(params[:store_pricing])
      flash[:notice] = 'StorePricing was successfully updated.'
      redirect_to({:action => "search", :store_pricing => {:barcode => @store_pricing.barcode}})
    else
      render :action => "edit"
    end
  end

  def destroy
    @store_pricing = StorePricing.find(params[:id])
    @store_pricing.destroy

    redirect_to({:action => "index"})
  end
end
