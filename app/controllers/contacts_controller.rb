class ContactsController < ApplicationController
  ContactMethodsTag = 'contacts_contact_methods'
  layout :with_sidebar
  filter_parameter_logging "user_password", "user_password_confirmation"

  private
  def set_management_cashier
    @management_cashier = OpenStruct.new(params[:management_cashier])
  end
  public
  before_filter :set_management_cashier

  def load_confidential_information
    @contact = Contact.find_by_id(@management_cashier.contact_id.to_i)
    @management_cashier.cashier_code = params[:this_cashier_code] if params[:this_cashier_code]
    uid = @management_cashier.cashier_code
    t = false
    u = nil
    if uid && (u = User.find_by_cashier_code(uid.to_i))
      t = true

      t = false if !u.can_login?

      Thread.current['user'] = Thread.current['cashier']
      t = false if ! u.can_view_disciplinary_information?
    else
      t = false
    end
    @valid_cashier_code = t
    @management_cashier.cashier_code = "" unless @valid_cashier_code
    render :update do |page|
      page.hide loading_indicator_id("confidential_information")
      page.replace_html 'confidential_information', :partial => 'disciplinary_actions'
    end
  end

  def roles
    @roles = Role.find(:all)
  end

  def email_list
    @multi_enabled = true
    @include_comma = (params[:include_comma] == "1")
    @show_email = (params[:show_email] == "1")
    @hide_full_name = (params[:hide_full_name] == "1")
    @include_first_name = (params[:include_first_name] == "1")
    @include_last_volunteer_date = (params[:include_last_volunteer_date] == "1")
    @include_last_donated_date = (params[:include_last_donated_date] == "1")
    @include_last_donated_contribution_only_date = (params[:include_last_donated_contribution_only_date] == "1")
    @include_last_donated_gizmos_only_date = (params[:include_last_donated_gizmos_only_date] == "1")

    @conditions = Conditions.new
    if params[:conditions]
      @conditions.apply_conditions(params[:conditions])
      @contacts = Contact.find(:all, :conditions => @conditions.conditions(Contact))
    else
      @show_email = true
    end
  end

  around_filter :transaction_wrapper

  def civicrm_sync
    _civicrm_sync
  end

  protected
  public

  before_filter :be_stupid

  def check_cashier_code
    uid = params[:cashier_code]
    append = (params[:append_this].nil? ? "" : "/#{params[:append_this]}")
    t = false
    u = nil
    if uid && (u = User.find_by_cashier_code(uid.to_i))
      t = true

      t = false if !u.can_login?

      ref = request.env["HTTP_REFERER"]
      ref = ref.split("/")
      c = ref[3]
      a = (ref[4] || "index") + append
      c = c.classify.pluralize + "Controller"
      Thread.current['user'] = Thread.current['cashier']
      t = false if ! ApplicationController.sb_has_required_privileges("contacts", a)
    else
      t = false
    end
    render :update do |page|
      page.hide loading_indicator_id("cashier_loading")
      page << (t ? "enable" : "disable") + "_cashierable();"
    end
  end

  def is_subscribed
    address = params[:address].to_s
    subscribed = NewsletterSubscriber.is_subscribed?(address)
    render :update do |page|
      page.hide loading_indicator_id("subscription_loading")
      if subscribed
        page << "$('subscribe').checked = true;"
        page << "$('subscribe_label').innerHTML = \"Already subscribed to newsletter.\";"
      else
        page << "$('subscribe').enable();"
        page << "$('subscribe').checked = false;"
        page << "$('subscribe_label').innerHTML = \"Subscribe to e-newsletter?\";"
      end
    end
  end

  protected
  def be_stupid
    @gizmo_context = GizmoContext.new(:name => 'contact')
  end
  public

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
      params[:defaults][:created_at_date] = Date.today.to_s
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
    @contact = Contact.find_by_id( params.fetch(:contact_id, '').strip.to_i )
    if @contact.nil?
      render :text => ""
    else
      render :partial => 'display', :locals => { :contact => @contact, :options => params['options'] || params}
    end
  end

  def new
    @contact = Contact.new
    @contact.state_or_province = Default['state_or_province']
    @contact.city = Default['city']
    @contact.country = Default['country']
    @options = params.merge({:action => "create", :id => rand(1000).to_s * 10})
    @new_options = @options.merge(:action => "new", :id => nil)
    @successful = true
    render :partial => 'new_edit', :locals => { :options => @options }
  end

  def create
    #    begin
    @contact = Contact.new(params[:contact])

    if params[:contact][:is_user].to_i != 0
      if !has_required_privileges("/create_logins")
        raise RuntimeError.new("You are not authorized to create a user login")
      end
      @contact.user = User.new(params[:user])
      @contact.user.roles = Role.find(params[:roles]) if params[:roles]
      if (@contact.user.roles - current_user.grantable_roles).length > 0
        raise RuntimeError.new("You are not authorized to grant those roles")
      end
    end
    @user = @contact.user
    @successful = _save
    #    rescue
    #      flash[:error], @successful  = $!.to_s, false
    #    end

    render :action => 'create.rjs'
  end

  def edit
      @contact = Contact.find(params[:id])
      @user = @contact.user or User.new
      @successful = !@contact.nil?

    @options = params.merge({ :action => "update", :id => params[:id] })
    @view_options = @options.merge(:action => "view")
    render :partial => 'new_edit', :locals => { :options => @options }
  end

  def update
      @contact = Contact.find(params[:id])
      @contact.attributes = params[:contact]
      if (uid = @management_cashier.cashier_code) && (u = User.find_by_cashier_code(uid.to_i)) && u.can_view_disciplinary_information?
        Thread.current['cashier'] = u
        u.will_not_updated_timestamps!
        u.last_logged_in = Date.today
        u.save
        @valid_cashier_code = true

        if params[:disciplinary_action_new_add] == "1"
          @contact.disciplinary_actions.build(params[:disciplinary_action_new])
        end
        @contact.disciplinary_actions.each do |da|
          h = params[("disciplinary_action_" + (da.id || "new").to_s).to_sym]
          unless h.nil?
            if h["mark_for_destruction"] == "1"
              h.delete("mark_for_destruction")
              da.mark_for_destruction
            else
              da.attributes = h
            end
          end
        end
      end
      if has_required_privileges("/create_logins") or has_privileges("contact_#{@contact.id}")
        if (params[:contact][:is_user].to_i != 0)
          @contact.user = User.new if !@contact.user
          unless has_required_privileges('/admin_user_accounts') or @contact.user.id.nil? or has_privileges("contact_#{@contact.id}")
            params[:user].delete('password')
            params[:user].delete('password_confirmation')
          end
          @contact.user.attributes = params[:user]
          if has_required_privileges("/create_logins")
            if params[:roles]
              newroles = Role.find(params[:roles])
              newroles = newroles + (@contact.user.roles - current_user.grantable_roles)
              if (newroles - (@contact.user.roles + current_user.grantable_roles)).length > 0
                raise RuntimeError.new("You are not authorized to grant those roles")
              end
              @contact.user.roles = newroles
            else
              @contact.user.roles = @contact.user.roles - current_user.grantable_roles
            end
          end
        elsif (@contact.user)
          @contact.user.destroy
          @contact.user = nil
        end
      end
      @user = @contact.user
      @successful = _save

    render :action => 'update.rjs'
  end

  def destroy
      @successful = Contact.find(params[:id]).destroy

    render :action => 'destroy.rjs'
  end

  def cancel
    @successful = true
    render :action => 'cancel.rjs'
  end

  def method_missing(symbol, *args)
    if /^auto_complete_for/.match(symbol.to_s)
      n = params[params["object_name"]][params[:field_name]].strip
      if params[:contact_context] and params[:contact_context].to_s.length > 0
        l = params[:contact_context].to_s.split(/ ,/).map(&:to_i)
        @contacts = Contact.search_by_type(l, n, :limit => 10)
      else
        @contacts = Contact.search(n, :limit => 10)
      end
      render :partial => 'auto_complete_list'
    else
      super
    end
  end

  #######
  private
  #######

  def _save
    @contact.contact_types = ContactType.find(params[:contact_types]) if params[:contact_types]
    @contact_methods = apply_line_item_data(@contact, ContactMethod)
    success = @contact.save
    if @contact.user
      success = success and @contact.user.save
    end
    if success
      @contact_methods.each{|x| x.save}
    end
    if @valid_cashier_code
      @contact.disciplinary_actions.select{|x| x.marked_for_destruction?}.each{|x| x.destroy}
      @contact.disciplinary_actions.select{|x| !x.marked_for_destruction?}.each{|x| x.save!}
    end
    return success
  end
end
