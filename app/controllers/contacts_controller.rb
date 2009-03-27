class ContactsController < ApplicationController
  ContactMethodsTag = 'contacts_contact_methods'
  layout :with_sidebar
  filter_parameter_logging "user_password", "user_password_confirmation"

  around_filter :transaction_wrapper
  before_filter :authorized_only, :except => [:check_cashier_code]
  before_filter :be_stupid

  def check_cashier_code
    uid = params[:cashier_code]
    t = ""
    if uid && (User.find_by_cashier_code(uid.to_i))
      t = "yep"
    else
      t = "nope"
    end
    render :text => t
  end

  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'contact')
  end

  class ForceRollback < RuntimeError
  end

  #########
  protected

  def transaction_wrapper
    Contact.transaction do
      yield
      raise ForceRollback.new if flash[:error]
    end
  rescue ForceRollback
  end

  def authorized_only
    #     if params[:id]
    #       contact_id = params[:id].to_i
    #     elsif params[:contact_id]
    #       contact_id = params[:id].to_i
    #     else
    #       contact_id = nil
    #     end
    #     requires_role_or_me(contact_id, 'CONTACT_MANAGER')
    requires_role('CONTACT_MANAGER', 'FRONT_DESK', 'STORE', 'VOLUNTEER_MANAGER')
  end

  ######
  public

  def reset_cashier_code
    u = User.find_by_id(params[:id])
    u.reset_cashier_code
    u.save
    render :update do |page|
      page << "$('user_cashier_code').value = #{u.cashier_code}"
      page.hide loading_indicator_id("cashier_code")
    end
  end

  def index
    lookup
    render :action => 'lookup'
  end

  def lookup
    if params[:defaults] == nil
      params[:defaults] = {}
      params[:defaults][:created_at_enabled] = "true"
    end

    if params[:contact]
      params[:defaults][:id] = params[:contact][:id]
      params[:defaults][:created_at_enabled] = "false"
      params[:defaults][:id_enabled] = "true"
    end

    if params[:contact_id]
      @contact = Contact.find_by_id(params[:contact_id])
      @thing = OpenStruct.new
      @thing.contact = @contact
    end

    @defaults = Conditions.new
    @defaults.apply_conditions(params[:defaults])
    @contacts = Contact.paginate(:all, :per_page => 20, :page => params[:page], :conditions => @defaults.conditions(Contact), :order => "id ASC")
  end

  def update_display_area
    @contact = Contact.find( params.fetch(:contact_id, '').strip )
    render :partial => 'display', :locals => { :@contact => @contact, :options => params['options'] || params}
  end

  def new
    @contact = Contact.new
    @contact.state_or_province = Default['state_or_province']
    @contact.city = Default['city']
    @contact.country = Default['country']
    @options = params.merge({:action => "create", :id => rand(1000).to_s * 10})
    @new_options = @options.merge(:action => "new", :id => nil)
    @successful = true
    render :partial => 'new_edit', :locals => { :@options => @options }
  end

  def create
    #    begin
    @contact = Contact.new(params[:contact])

    if params[:contact][:is_user].to_i != 0
      if !has_role?(:ADMIN)
        raise RuntimeError.new("You are not authorized to create a user login")
      end
      @contact.user = User.new(params[:user])
      @contact.user.roles = Role.find(params[:roles]) if params[:roles]
    end
    @user = @contact.user
    @successful = _save
    #    rescue
    #      flash[:error], @successful  = $!.to_s, false
    #    end

    render :action => 'create.rjs'
  end

  def edit
    begin
      @contact = Contact.find(params[:id])
      @user = @contact.user or User.new
      @successful = !@contact.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    @options = params.merge({ :action => "update", :id => params[:id] })
    @view_options = @options.merge(:action => "view")
    render :partial => 'new_edit', :locals => { :@options => @options }
  end

  def update
    begin
      @contact = Contact.find(params[:id])
      @contact.attributes = params[:contact]
      if has_role_or_is_me?(@contact.id, :ADMIN)
        if (params[:contact][:is_user].to_i != 0)
          @contact.user = User.new if !@contact.user
          @contact.user.attributes = params[:user]
          if has_role?(:ADMIN)
            if params[:roles]
              @contact.user.roles = Role.find(params[:roles])
            else
              @contact.user.roles.clear
            end
          end
        elsif (@contact.user)
          @contact.user.destroy
          @contact.user = nil
        end
      end
      @user = @contact.user
      @successful = _save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    render :action => 'update.rjs'
  end

  def destroy
    begin
      @successful = Contact.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    render :action => 'destroy.rjs'
  end

  def cancel
    @successful = true
    render :action => 'cancel.rjs'
  end

  def method_missing(symbol, *args)
    if /^auto_complete_for/.match(symbol.to_s)
      #:MC: gah!  the auto_complete_field method screws up the arguments with that "amp;".
      @contacts = Contact.search(params[params["amp;object_name"]][params[:field_name]].strip, :limit => 10)
      render :partial => 'auto_complete_list'
    else
      super
    end
  end

  #######
  private
  #######

  def _apply_line_item_data(contact)
    @contact_methods = []
    if params[:contact_methods]
      for contact_method in params[:contact_methods].values
        p = ContactMethod.new(contact_method)
        @contact_methods << p
      end
    end
    contact.contact_methods = @contact_methods
  end

  def _save
    @contact.contact_types = ContactType.find(params[:contact_types]) if params[:contact_types]
    success = @contact.save
    _apply_line_item_data(@contact)
    if @contact.user
      success = @contact.user.save and success
    end
    return success
  end
end
