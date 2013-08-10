class SystemPricingsController < ApplicationController
  layout :with_sidebar

  protected
  before_filter :fix_pricing_values_multiselect
  def fix_pricing_values_multiselect
    params[:system_pricing][:pricing_value_ids] = [params[:system_pricing][:pricing_value_ids]].flatten.map{|x| x.split(",")}.flatten if params[:system_pricing] and params[:system_pricing][:pricing_value_ids]
  end

  public

  def index
    @system_pricing = SystemPricing.new
    @system_pricings = SystemPricing.find(:all, :conditions => ['id IN (SELECT DISTINCT system_id FROM system_pricings) AND id NOT IN (SELECT DISTINCT system_id FROM gizmo_events)'])
  end

  def calculate
    @system_pricing = SystemPricing.new(params[:system_pricing])
    diff = 0
    if params[:pricing_bonuses]
      params[:pricing_bonuses].each do |k, x|
        diff += x.delete("amount_cents").to_i
      end
    end
    @system_pricing.autodetect_looked_up_values
    @system_pricing.set_calculated_price
    h = {}
    @system_pricing.pricing_values.each do |x|
      h[x.pricing_component_id] ||= []
      h[x.pricing_component_id] << x
    end
    render :update do |page|
      @system_pricing.pricing_values.select{|x| x.pricing_component.lookup_column.to_s.length > 0 && x.pricing_component.lookup_table.to_s.length > 0}.each do |c|
        if c.pricing_component.use_value_as_score
          page << '$("system_pricing_pricing_component_values_component_' + c.pricing_component_id.to_s + '").value = ' + c.value + ';'
        else
          page << '$("pricing_values_for_' + c.pricing_component_id.to_s + '").value = ' + c.id.to_s + ';'
        end
      end
      page.hide loading_indicator_id("calculated_price")
      page << '$("calculated_price").innerHTML = "$' + @system_pricing.calculated_price + '";'
      page << '$("total_price").innerHTML = "$' + (@system_pricing.calculated_price_cents + diff).to_dollars + '";'
      page << '$("equation").innerHTML = "' + @system_pricing.to_equation + '";'
      seen_c = []
      h.each do |k, v|
        page << '$("pricing_component_' + k.to_s + '").innerHTML = ' + v.inject(0){|t, x| t+= x.value_cents}.to_dollars.to_json + ';'
      end
      @system_pricing.pricing_type.pricing_components.each do |c|
        unless h.keys.include?(c.id)
          page << '$("pricing_component_' + c.id.to_s + '").innerHTML = "0.00";'
        end
      end
      
    end
  end

  def show
    @system_pricing = SystemPricing.find(params[:id])

    @system = @system_pricing.system
    if @system
      @spec_sheet = @system_pricing.spec_sheet
      @values = @system_pricing.pricing_hash
      @field_errors = @system_pricing.field_errors
    end
  end

  def edit
    @system_pricing = SystemPricing.find(params[:id])

    @system = @system_pricing.system
    if @system
      @spec_sheet = @system_pricing.spec_sheet
      @values = @system_pricing.pricing_hash
      @field_errors = @system_pricing.field_errors
    end
  end

  def create
    @system_pricing = SystemPricing.new(params[:system_pricing])
    @system = @system_pricing.system

    unless @system_pricing.spec_sheet
      @system_pricing.autodetect_spec_sheet
    end

    if @system_pricing.pricing_type && params[:system_pricing][:pricing_value_ids].nil?
      @system_pricing.autodetect_values
    end

    if @system_pricing.pricing_type
      @system_pricing.autodetect_looked_up_values
    end

    unless @system_pricing.pricing_type
      @system_pricing.autodetect_type_and_values
      @system_pricing.autodetect_looked_up_values
    end

    if @system
      @spec_sheet = @system_pricing.spec_sheet
      @values = @system_pricing.pricing_hash
      @field_errors = @system_pricing.field_errors
    end

    pricing_bonuses = apply_line_item_data(@system_pricing, PricingBonus, "pricing_bonuses")

    @system_pricing.pricing_bonuses = pricing_bonuses
    if @system_pricing.magic_bit && @system_pricing.save
      pricing_bonuses.each{|x| x.system_pricing = @system_pricing}
      pricing_bonuses.each{|x| x.save}
      flash[:notice] = 'SystemPricing was successfully created.'
      redirect_to({:action => "show", :id => @system_pricing.id})
    else
      render :action => "new"
    end
  end

  def update
    @system_pricing = SystemPricing.find(params[:id])
    pricing_bonuses = apply_line_item_data(@system_pricing, PricingBonus, "pricing_bonuses")
    @system = @system_pricing.system
    if @system
      @spec_sheet = @system_pricing.spec_sheet
      @values = @system_pricing.pricing_hash
      @field_errors = @system_pricing.field_errors
    end

    @system_pricing.pricing_bonuses = pricing_bonuses
    if @system_pricing.update_attributes(params[:system_pricing])
      pricing_bonuses.each{|x| x.system_pricing = @system_pricing}
      pricing_bonuses.each{|x| x.save}
      flash[:notice] = 'SystemPricing was successfully updated.'
      redirect_to({:action => "show", :id => @system_pricing.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @system_pricing = SystemPricing.find(params[:id])
    @system_pricing.destroy

    redirect_to({:action => "index"})
  end
end
