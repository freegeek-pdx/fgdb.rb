# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  layout "application"
  helper :cashiers
  helper :conditions

=begin
    protect_from_forgery
    post_list = ["create", "update", "xml_create"]
    ajax_post_list = ["new", "edit", "component_update", "update_display_area"]
    verify :method => :get, :except => post_list + ajax_post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
    verify :method => :post, :xhr => true, :only => post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
    verify :method => :post, :only => post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
=end

  before_filter :set_cashier
  def set_cashier
    uid = _set_cashier(params)
    if uid && (u = User.find_by_cashier_code(uid.to_i))
      Thread.current['cashier'] = u
    else
      logger.warn "Cashier not found" # die better
    end
  end

  def add_to_session_labels(id)
    session[:labels] ||= []
    session[:labels] << id if !session[:labels].include?(id)
  end

  def remove_from_session_labels(things)
    session[:labels] ||= []
    session[:labels].delete_if{|x| things.include?(x)}
  end

  def list_labels_in_session
    session[:labels] ||= []
  end

  def skedjulnator_role
    requires_role("SKEDJULNATOR")
  end

  def _set_cashier(hash)
    return hash["cashier_code"] if hash.keys.include?("cashier_code")
    for i in hash.values.select{|x| x.class == Hash}
      x = _set_cashier(hash)
      return x if !x.nil?
    end
    return nil
  end

  def current_cashier
    Thread.current['cashier']
  end

  def with_sidebar
    "with_sidebar.html.erb"
  end

  before_filter :authorize

  def authorize
    x = current_user()
    if x.kind_of?(User)
      @current_user = x
    else
      @current_user = nil
    end
    Thread.current['user'] = @current_user
  end

  def is_me?(contact_id)
    current_user and current_user.contact_id == contact_id.to_i
  end

  def has_role_or_is_me?(contact_id, *roles)
    (contact_id and is_me?(contact_id)) or has_role?(*roles)
  end

  def has_role?(*roles)
    logged_in? and current_user.has_role?(*roles)
  end

  def requires_role(*roles)
    if has_role?(*roles)
      return true
    else
      session[:unauthorized_error] = true
      session[:unauthorized_controller] = controller_name()
      session[:unauthorized_action] = action_name()
      redirect_to :controller => 'sidebar_links'
      return false
    end
  end

  def requires_role_or_me(contact_id, *roles)
    if has_role_or_is_me?(contact_id.to_i, *roles)
      return true
    else
      session[:unauthorized_error] = true
      session[:unauthorized_controller] = controller_name()
      session[:unauthorized_action] = action_name()
      redirect_to :controller => 'sidebar_links'
      return false
    end
  end

  before_filter :fix_null_date

  def fix_this_null_date (c1, c2)
    if params[c1]
      if params[c1][c2]
        if params[c1][c2].empty?
          params[c1][c2] = nil
        end
      end
    end
  end

  def fix_null_date
    return if !([:coverage_types, :customizations, :frequency_types, :holidays, :jobs, :meetings, :rr_items, :rr_sets, :schedules, :shifts, :standard_shifts, :unavailabilities, :vacations, :weekdays, :workers, :worker_types, :work_shifts].map{|x| x.to_s}.include?(params[:controller]) && ["update","create"].include?(params[:action]))
    # fields to check. these are date fields that allow NULL
    # values in the database. the dhtml-calendar plugin passes an
    # empty string when the date is left blank, this turns into
    # an arbitrary and unwanted date rather than a NULL. fix
    # these by explicitly setting these values to nil. 
    fix_this_null_date(:holiday, :holiday_date)
    fix_this_null_date(:meeting, :meeting_date)
    fix_this_null_date(:meeting, :effective_date)
    fix_this_null_date(:meeting, :ineffective_date)
    fix_this_null_date(:rr_set, :effective_date)
    fix_this_null_date(:rr_set, :ineffective_date)
    fix_this_null_date(:schedule, :effective_date)
    fix_this_null_date(:schedule, :ineffective_date)
    fix_this_null_date(:shift, :shift_date)
    fix_this_null_date(:shift, :effective_date)
    fix_this_null_date(:shift, :ineffective_date)
    fix_this_null_date(:standard_shift, :shift_date)
    fix_this_null_date(:unavailability, :effective_date)
    fix_this_null_date(:unavailability, :ineffective_date)
    fix_this_null_date(:vacation, :effective_date)
    fix_this_null_date(:vacation, :ineffective_date)
    fix_this_null_date(:work_shift, :shift_date)
    fix_this_null_date(:work_shift, :effective_date)
    fix_this_null_date(:work_shift, :ineffective_date)
    fix_this_null_date(:worker, :effective_date)
    fix_this_null_date(:worker, :ineffective_date)
  end
end
