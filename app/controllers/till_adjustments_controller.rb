class TillAdjustmentsController < ApplicationController
  layout :with_sidebar
  def inventory_settings
    @date = _parse_date(Default["inventory_lock_end"])
    @settings = OpenStruct.new({:date => @date})
  end
  def _parse_date(d)
    return "" if d.nil? or (!d) or d.length == 0
    Date.parse(d).to_s
  end
  def save_inventory_settings
    @date = _parse_date(params[:settings] && params[:settings][:date])
    Default["inventory_lock_end"] = @date
    @settings = OpenStruct.new({:date => @date})
    render :action => "inventory_settings"
  end

  def method_missing(n)
    redirect_to params.merge(:model => params[:controller], :controller => "admin")
  end
end

