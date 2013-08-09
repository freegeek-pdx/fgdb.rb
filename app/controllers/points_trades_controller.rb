class PointsTradesController < ApplicationController
  layout :with_sidebar
  protected
  public

  def index
    new
    render :action => "new"
  end

  def new
    @points_trades = PointsTrade.find(:all)
    @points_trade = PointsTrade.new
  end

  def edit
    @points_trades = PointsTrade.find(:all)
    @points_trade = PointsTrade.find(params[:id])
    render :action => "new"
  end

  def create
    @points_trades = PointsTrade.find(:all)
    @points_trade = PointsTrade.new(params[:points_trade])

    @successful = @points_trade.save
    render :action => 'save.rjs'
  end

  def update
    @points_trades = PointsTrade.find(:all)
    @points_trade = PointsTrade.find(params[:id])

    @successful = @points_trade.update_attributes(params[:points_trade])
    render :action => "save.rjs"
  end

  def destroy
    @points_trade = PointsTrade.find(params[:id])
    @successful = @points_trade.destroy
    render :action => "destroy.rjs"
  end
end
