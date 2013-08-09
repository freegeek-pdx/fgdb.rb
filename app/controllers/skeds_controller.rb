class SkedsController < ApplicationController
  protected
  public

  layout :with_sidebar

  def move_higher
    @sked = Sked.find(params[:id])
    @roster = @sked.rosters.select{|x| x.id == params[:roster_id].to_i}.first
    raise unless @roster
    @sked.rosters.move_higher(@roster)
    @sked.save
    redirect_to :back
  end

  def move_lower
    @sked = Sked.find(params[:id])
    @roster = @sked.rosters.select{|x| x.id == params[:roster_id].to_i}.first
    raise unless @roster
    @sked.rosters.move_lower(@roster)
    @sked.save
    redirect_to :back
  end

  def index
    @skeds = Sked.find(:all)
  end

  def show
    @sked = Sked.find(params[:id])
  end

  def new
    @sked = Sked.new
  end

  def edit
    @sked = Sked.find(params[:id])
  end

  def create
    list = params[:sked].delete(:roster_ids)
    @sked = Sked.new(params[:sked])

    if @sked.save
      @sked.roster_ids = list
      @sked.save
      flash[:notice] = 'Sked was successfully created.'
      redirect_to({:action => "show", :id => @sked.id})
    else
      render :action => "new"
    end
  end

  def update
    params[:sked][:roster_ids] ||= []

    @sked = Sked.find(params[:id])

    if @sked.update_attributes(params[:sked])
      flash[:notice] = 'Sked was successfully updated.'
      redirect_to({:action => "show", :id => @sked.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @sked = Sked.find(params[:id])
    @sked.destroy

    redirect_to({:action => "index"})
  end
end
