class PricingValuesController < ApplicationController
  layout :with_sidebar

  protected
  public

  def new
    @pricing_component = PricingComponent.find(params[:pricing_component_id])
    @pricing_value = PricingValue.new
    @pricing_value.pricing_component = @pricing_component
  end

  def edit
    @pricing_value = PricingValue.find(params[:id])
    @pricing_component = @pricing_value.pricing_component
  end

  def create
    @pricing_component = PricingComponent.find(params[:pricing_component_id])
    @pricing_value = PricingValue.new(params[:pricing_value])
    @pricing_value.pricing_component = @pricing_component

    if @pricing_value.save
      flash[:notice] = 'PricingValue was successfully created.'
      redirect_to({:action => "edit", :controller => "pricing_components", :id => @pricing_component.id})
    else
      render :action => "new"
    end
  end

  def update
    orig_pricing_value = PricingValue.find(params[:id])
    @pricing_component = orig_pricing_value.pricing_component
    @pricing_value = orig_pricing_value.clone

    if @pricing_value.update_attributes(params[:pricing_value]) && @pricing_value.save
      orig_pricing_value.replaced_by_id = @pricing_value.id
      orig_pricing_value.ineffective_on = DateTime.now
      orig_pricing_value.save!
      flash[:notice] = 'PricingValue was successfully updated.'
      redirect_to({:action => "edit", :controller => "pricing_components", :id => @pricing_component.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @pricing_value = PricingValue.find(params[:id])
    @pricing_component = @pricing_value.pricing_component
    @pricing_value.ineffective_on = DateTime.now
    @pricing_value.save!

    redirect_to({:action => "edit", :controller => "pricing_components", :id => @pricing_component.id})
  end
end
