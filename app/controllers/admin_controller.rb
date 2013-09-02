class AdminController < ApplicationController
  layout :with_sidebar

  # TODO: restrict whole deal to ADMIN

  before_filter :set_model
  private
  def set_model
    if params[:model]
      @model_param = params[:model]
      @model_name = @model_param.classify
      @model_human = @model_param.humanize
      @model = @model_name.constantize
    end
  end
  public

  def index
    # list models supported here
    @models = ["defaults"]
  end

# TODO: have pagination settings, default sort order, default scope,
#       etc etc etc all defined the rails way (default_scope how?)

  def list
    @objects = @model.find(:all)
  end

# NOTE: could even set future search conditions for the index page,
#       in the model available through standard interface
#
#  def show
#    @<%= file_name %> = <%= class_name %>.find(params[:id])
#  end
#
#  def new
#    @<%= file_name %> = <%= class_name %>.new
#  end
#
#TODO: models will have a .disallow_modifcation_of_these_fields method,
#defaulting to created_*, updated_*, etc, but also for name/description
#of defaults, etc.
#  def edit
#    @<%= file_name %> = <%= class_name %>.find(params[:id])
#  end
#
#  def create
#    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
#
#    if @<%= file_name %>.save
#      flash[:notice] = '<%= class_name %> was successfully created.'
#                                                     redirect_to({:action => "show", :id => @<%= file_name %>.id})
#    else
#      render :action => "new"
#    end
#  end
#
#  def update
#    @<%= file_name %> = <%= class_name %>.find(params[:id])
#
#    if @<%= file_name %>.update_attributes(params[:<%= file_name %>])
#      flash[:notice] = '<%= class_name %> was successfully updated.'
#  redirect_to({:action => "show", :id => @<%= file_name %>.id})
#    else
#      render :action => "edit"
#    end
#  end
#
#  def destroy
#    @<%= file_name %> = <%= class_name %>.find(params[:id])
#    @<%= file_name %>.destroy
#
#    redirect_to({:action => "index"})
#  end
end
