require 'barby'
require 'barby/outputter/rmagick_outputter'

class BarcodeController < ApplicationController
  def barcode
    respond_to do |format|
      format.gif { render :text => Barby::Code39.new(params[:id]).to_gif(:margin => 0) }
    end
  end
end
