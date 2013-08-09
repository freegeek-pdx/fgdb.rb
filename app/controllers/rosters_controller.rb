class RostersController < ApplicationController
  protected
  public

  layout :with_sidebar

  def index
    @rosters = Roster.find(:all)
  end

  def show
    @roster = Roster.find(params[:id])
  end

  def new
    @roster = Roster.new
  end

  def edit
    @roster = Roster.find(params[:id])
  end

  def create
    @roster = Roster.new(params[:roster])

    if @roster.save
      flash[:notice] = 'Roster was successfully created.'
      redirect_to({:action => "show", :id => @roster.id})
    else
      render :action => "new"
    end
  end

  def update
    params[:roster][:sked_ids] ||= []

    @roster = Roster.find(params[:id])

    if @roster.update_attributes(params[:roster])
      flash[:notice] = 'Roster was successfully updated.'
      redirect_to({:action => "show", :id => @roster.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @roster = Roster.find(params[:id])
    @roster.destroy

    redirect_to({:action => "index"})
  end
end
