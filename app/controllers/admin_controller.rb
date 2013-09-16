class AdminController < ApplicationController
  layout :with_sidebar

  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }

  before_filter :set_model
  private
  def set_model
    # list models supported here
    @models = ["defaults", "customizations", "gizmo_type_groups", "recycling_shipments", "till_adjustments", "rosters", "skeds", "resources", "jobs", "worker_types", "rr_sets", "rr_items", "weekdays"]
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

  def reorder_associated
    @admin = @model.find(params[:id])
    @association = params[:association]
    @list = @admin.send(@association.to_sym)
  end

  def move_associated_up
    reorder_associated
    @other = @list.select{|x| x.id == params[:other_id].to_i}.first
    raise unless @other
    @list.move_higher(@other)
    @admin.save
    redirect_to :action => "reorder_associated", :id => @admin.id, :association => @association
  end

  def move_associated_down
    reorder_associated
    @other = @list.select{|x| x.id == params[:other_id].to_i}.first
    raise unless @other
    @list.move_lower(@other)
    @admin.save
    redirect_to :action => "reorder_associated", :id => @admin.id, :association => @association
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
    gimme_onesec = {}

    for x in @model.reflect_on_all_associations(:has_and_belongs_to_many)
      field = (x.name.to_s.singularize + "_ids").to_sym
      if params[@model_access] && params[@model_access][field]
        gimme_onesec[field] = params[@model_access].delete(field)
      end
    end

    @admin = @model.new(params[@model_access])

#
    if @admin.save
      if gimme_onesec.length > 0
        gimme_onesec.each do |k, v|
          @admin.send((k.to_s + "=").to_sym, v)
        end
        @admin.save
      end
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
