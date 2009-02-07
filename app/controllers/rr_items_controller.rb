class RrItemsController < ApplicationController
  layout "skedjulnator"
  before_filter :skedjulnator_role

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @rr_items = RrItem.paginate :per_page => 10, :page => params[:page]
  end

  def show
    @rr_item = RrItem.find(params[:id])
  end

  def new
    @rr_item = RrItem.new(:rr_set_id => params[:rr_set_id])
  end

  def create
    @rr_item = RrItem.new(params[:rr_item])
    if @rr_item.save
      flash[:notice] = 'RrItem was successfully created.'
      redirect_to :action => 'list', :controller => 'rr_sets'
    else
      render :action => 'new'
    end
  end

  def edit
    @rr_item = RrItem.find(params[:id])
  end

  def update
    @rr_item = RrItem.find(params[:id])
    if @rr_item.update_attributes(params[:rr_item])
      flash[:notice] = 'RrItem was successfully updated.'
      redirect_to :action => 'show', :id => @rr_item
    else
      render :action => 'edit'
    end
  end

  def destroy
    RrItem.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
