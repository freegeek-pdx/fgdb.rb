class AdminController < ApplicationController
  layout :with_sidebar

  before_filter :set_model
  private
  def set_model
    # list models supported here
    @models = ["defaults"]
    if params[:model]
      @model_param = params[:model]
      @model_name = @model_param.classify
      @model_human = @model_param.humanize.singularize
      @model_access = @model_param.singularize.to_sym
      @model = @model_name.constantize
    end
  end
  public

  def index
    if @model
      redirect_to :action => "list"
    end
  end

# TODO: have pagination settings, default sort order, default scope,
#       etc etc etc all defined the rails way (default_scope how?)

  def list
    @objects = @model.paginate :per_page => @model.per_page, :page => params[:page]
  end

# NOTE: could even set future search conditions for the index page,
#       in the model available through standard interface
#
  def show
    @admin = @model.find(params[:id])
  end
#
  def new
    @admin = @model.new
  end

  def edit
    @admin = @model.find(params[:id])
  end
#
  def create
    @admin = @model.new(params[@model_access])
#
    if @admin.save
      flash[:notice] = "#{@model_name} was successfully created."
      redirect_to({:action => "show", :id => @admin.id})
    else
      render :action => "new"
    end
  end

  private
  def redirect_to(h)
    super(h.class == Hash ? h.merge(:model => params[:model]) : h)
  end
  public

  def update
    @admin = @model.find(params[:id])

    if @admin.update_attributes(params[@model_access])
      flash[:notice] = "#{@model_human} was successfully updated."
      redirect_to({:action => "show", :id => @admin.id})
    else
      render :action => "edit"
    end
  end
#
#  def destroy
#    @admin = @model.find(params[:id])
#    @admin.destroy
#
#    redirect_to({:action => "index"})
#  end
end
