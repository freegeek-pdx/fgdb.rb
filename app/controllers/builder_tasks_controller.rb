class BuilderTasksController < ApplicationController
  layout :with_sidebar
  protected
  public

  def sign_off
    u = User.find_by_cashier_code(params[:cashier_code])
    s = BuilderTask.find(params[:id])
    # if no admins, only people with actual build_instructor role, do this: u.privileges.include?(required_privileges("show/sign_off").flatten.first)
    # do not allow when users is the contact for the BT
    if u.contact_id != s.contact_id && u.has_privileges(ApplicationController.required_privileges("spec_sheets", "show/sign_off").flatten.first)
      s.signed_off_by=(u)
      s.save!
    end
    redirect_to :back
  end

  def index
    redirect_to :controller => "spec_sheets", :action => "index"
  end

  def show
    @builder_task = BuilderTask.find(params[:id])
    _do_redirect_if_ss
  end

  def new
    @builder_task = BuilderTask.new
  end

  def edit
    @builder_task = BuilderTask.find(params[:id])
    _do_redirect_if_ss
  end

  def create
    @builder_task = BuilderTask.new(params[:builder_task])

    if @builder_task.save
      flash[:notice] = 'BuilderTask was successfully created.'
      redirect_to({:action => "show", :id => @builder_task.id})
    else
      render :action => "new"
    end
  end

  def update
    @builder_task = BuilderTask.find(params[:id])

    if @builder_task.update_attributes(params[:builder_task])
      flash[:notice] = 'BuilderTask was successfully updated.'
      redirect_to({:action => "show", :id => @builder_task.id})
    else
      render :action => "edit"
    end
  end

  private
  def _do_redirect_if_ss
    redirect_to :controller => "spec_sheets", :action => params[:action], :id => @builder_task.spec_sheet.id if @builder_task.spec_sheet
  end
end
