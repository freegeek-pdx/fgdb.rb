class RecyclingShipmentsController < ApplicationController

  layout :with_sidebar

  def index
    @conditions = Conditions.new
    if params[:conditions]
      @conditions.apply_conditions(params[:conditions])
    else
      @conditions.unresolved_shipment_enabled = true
    end
    @recycling_shipments = RecyclingShipment.paginate(:page => params[:page], :conditions => @conditions.conditions(RecyclingShipment), :order => "contacts.sort_name, received_at ASC", :per_page => 50, :include => [:contact])
  end

  def search
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    session[:recycling_shipment_conditions] = params[:conditions] if @conditions.valid?
    @recycling_shipments = RecyclingShipment.paginate(:page => params[:page], :conditions => @conditions.conditions(RecyclingShipment), :order => "contacts.sort_name, received_at ASC", :per_page => 50, :include => [:contact])
    render :action => "index"
  end

  def new
    @recycling_shipment = RecyclingShipment.new
    @back_url = redirect_location
  end

  def edit
    @recycling_shipment = RecyclingShipment.find(params[:id])
    @back_url = redirect_location
  end

  def create
    @recycling_shipment = RecyclingShipment.new(params[:recycling_shipment])

    if @recycling_shipment.save
      flash[:notice] = 'RecyclingShipment was successfully created.'
      redirect_to(redirect_location)
    else
      render :action => "new"
    end
  end

  def update
    @recycling_shipment = RecyclingShipment.find(params[:id])

    if @recycling_shipment.update_attributes(params[:recycling_shipment])
      flash[:notice] = 'RecyclingShipment was successfully updated.'
      redirect_to(redirect_location)
    else
      render :action => "edit"
    end
  end

  def destroy
    @recycling_shipment = RecyclingShipment.find(params[:id])
    @recycling_shipment.destroy

    redirect_to(redirect_location)
  end

  protected
  def redirect_location
    if session[:recycling_shipment_conditions]
      return {:action => "index", :conditions => session[:recycling_shipment_conditions]}
    else
      return {:action => "index"}
    end
  end
end
