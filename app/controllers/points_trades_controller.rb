class PointsTradesController < ApplicationController
  layout :with_sidebar

  before_filter :authorized_only
  def authorized_only
    requires_role('VOLUNTEER_MANAGER')
  end

  def index
    @points_trades = PointsTrade.find(:all)
  end

  def new
    @points_trade = PointsTrade.new
  end

  def edit
    @points_trade = PointsTrade.find(params[:id])
    render :action => "new"
  end

  def create
    @points_trade = PointsTrade.new(params[:points_trade])

    if @points_trade.save
      flash[:notice] = 'PointsTrade was successfully created.'
      redirect_to({:action => "index"})
    else
      render :action => "new"
    end
  end

  def update
    @points_trade = PointsTrade.find(params[:id])

    if @points_trade.update_attributes(params[:points_trade])
      flash[:notice] = 'PointsTrade was successfully updated.'
      redirect_to({:action => "index"})
    else
      render :action => "new"
    end
  end

  def destroy
    @points_trade = PointsTrade.find(params[:id])
    @points_trade.destroy

    redirect_to(points_trades_url)
  end
end
