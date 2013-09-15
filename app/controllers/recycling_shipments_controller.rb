class RecyclingShipmentsController < ApplicationController
  def method_missing(n)
    redirect_to params.merge(:model => params[:controller], :controller => "admin")
  end
end

