class VolunteerTasksController < ApplicationController
  layout :with_sidebar
  before_filter :authorized_only
  before_filter :be_stupid

  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'contact')
  end

  #########
  protected

  def authorized_only
    if params[:contact_id]
      contact_id = params[:contact_id].to_i
    elsif params[:volunteer_task] and params[:volunteer_task][:contact_id]
      contact_id = params[:volunteer_task][:contact_id].to_i
    else
      contact_id = nil
    end
    requires_role_or_me(contact_id, 'ROLE_VOLUNTEER_MANAGER')
  end

  ######
  public

  def index
    list
    render :action => 'list'
  end

  def list
    if params[:contact_id]
      params[:limit_by_contact_id] = true
    end
  end

  # All posts to change variables like sort values or page changes go through this action
  def component_update
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating
    component
  end

  def component
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = VolunteerTask.columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ?
      "#{VolunteerTask.table_name}.date_performed DESC" :
      @sort_sql  + " " + current_sort_direction(params)
    options = {
      :order => @sort_by,
      :per_page => 20,
      :include => [
        :volunteer_task_type,
        :contact
      ]
    }
    if params[:limit_by_contact_id]
      options[:conditions] = ['contact_id = ?', params[:contact_id]]
      @contact = Contact.find(params[:contact_id])
    end
    options[:page] = params[:page]
    @volunteer_tasks = VolunteerTask.paginate(options)
    render :action => "component", :layout => false
  end

  def new
    @volunteer_task = VolunteerTask.new
    @volunteer_task.duration = nil
    @volunteer_task.date_performed = Date.today
    @volunteer_task.contact_id = params[:contact_id] if params[:limit_by_contact_id]
    @successful = true

    return render(:action => 'new.rjs')
  end

  def create
    begin
      @volunteer_task = VolunteerTask.new(params[:volunteer_task])
      @volunteer_task.community_service_type = nil unless CommunityServiceType.exists?(@volunteer_task.community_service_type_id)
      @successful = @volunteer_task.save
      @contact = @volunteer_task.contact
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'create.rjs')
  end

  def edit
    begin
      @volunteer_task = VolunteerTask.find(params[:id])
      @successful = !@volunteer_task.nil?
    rescue
      flash[:error], @successful  = "<pre>#{$!.backtrace.to_yaml}</pre>", false
    end

    return render(:action => 'edit.rjs')
  end

  def update
    begin
      @volunteer_task = VolunteerTask.find(params[:id])
      @volunteer_task.community_service_type = nil unless CommunityServiceType.exists?(@volunteer_task.community_service_type_id)
      @successful = @volunteer_task.update_attributes(params[:volunteer_task])
      @contact = @volunteer_task.contact
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'update.rjs')
  end

  def destroy
    begin
      task = VolunteerTask.find(params[:id])
      @contact = task.contact
      @successful = task.destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'destroy.rjs')
  end

  def cancel
    @successful = true
    return render(:action => 'cancel.rjs')
  end

end
