class RrSetsController < ApplicationController
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
    @rr_sets = RrSet.paginate :per_page => 10, :page => params[:page]
  end

  def show
    @rr_set = RrSet.find(params[:id])
  end

  def new
    @rr_set = RrSet.new
  end

  def create
    @rr_set = RrSet.new(params[:rr_set])
    if @rr_set.save
      flash[:notice] = 'RrSet was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @rr_set = RrSet.find(params[:id])
  end

  def update
    @rr_set = RrSet.find(params[:id])
    if @rr_set.update_attributes(params[:rr_set])
      flash[:notice] = 'RrSet was successfully updated.'
      redirect_to :action => 'show', :id => @rr_set
    else
      render :action => 'edit'
    end
  end

  def check_date
    if params[:checker]
      string_date = params[:checker]["check_date"]
      if string_date
        check_date = Date.strptime( string_date, '%Y-%m-%d' )
      else
        check_date = Date.today
      end
    else
      check_date = Date.today
    end
    if check_date == Date.today
      datestring = 'today (' + check_date.strftime( '%b %d, %Y' ) + ')' 
    else
      datestring = 'on ' + check_date.strftime( '%b %d, %Y' ) 
    end
    @rr_set = RrSet.find(params[:id])
    if @rr_set.occurs? check_date 
      flash[:notice] = @rr_set.name + ' occurs ' + datestring
      redirect_to :action => 'list', :id => @rr_set
    else
      flash[:notice] = 'Event does not occur ' + datestring
      render :action => 'check_date'
    end
  end

  def destroy
    RrSet.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
