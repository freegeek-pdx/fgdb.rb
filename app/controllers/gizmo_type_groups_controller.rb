class GizmoTypeGroupsController < ApplicationController
  protected
  public

  # GET /gizmo_type_groups
  # GET /gizmo_type_groups.xml
  def index
    @gizmo_type_groups = GizmoTypeGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @gizmo_type_groups }
    end
  end

  # GET /gizmo_type_groups/1
  # GET /gizmo_type_groups/1.xml
  def show
    @gizmo_type_group = GizmoTypeGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @gizmo_type_group }
    end
  end

  # GET /gizmo_type_groups/new
  # GET /gizmo_type_groups/new.xml
  def new
    @gizmo_type_group = GizmoTypeGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @gizmo_type_group }
    end
  end

  # GET /gizmo_type_groups/1/edit
  def edit
    @gizmo_type_group = GizmoTypeGroup.find(params[:id])
  end

  # POST /gizmo_type_groups
  # POST /gizmo_type_groups.xml
  def create
    @gizmo_type_group = GizmoTypeGroup.new(params[:gizmo_type_group])

    respond_to do |format|
      if @gizmo_type_group.save
        flash[:notice] = 'GizmoTypeGroup was successfully created.'
        format.html { redirect_to(@gizmo_type_group) }
        format.xml  { render :xml => @gizmo_type_group, :status => :created, :location => @gizmo_type_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @gizmo_type_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /gizmo_type_groups/1
  # PUT /gizmo_type_groups/1.xml
  def update
    @gizmo_type_group = GizmoTypeGroup.find(params[:id])

    respond_to do |format|
      if @gizmo_type_group.update_attributes(params[:gizmo_type_group])
        flash[:notice] = 'GizmoTypeGroup was successfully updated.'
        format.html { redirect_to(@gizmo_type_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @gizmo_type_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /gizmo_type_groups/1
  # DELETE /gizmo_type_groups/1.xml
  def destroy
    @gizmo_type_group = GizmoTypeGroup.find(params[:id])
    @gizmo_type_group.destroy

    respond_to do |format|
      format.html { redirect_to(gizmo_type_groups_url) }
      format.xml  { head :ok }
    end
  end
end
