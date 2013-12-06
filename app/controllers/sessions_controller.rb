# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  filter_parameter_logging "password"

  # render new.rhtml
  def new
  end

  def create
    disabled_user = User.find_by_login_and_can_login(params[:login].to_s.strip, false)
    if disabled_user
      if disabled_user.reason_cannot_login && disabled_user.reason_cannot_login.to_s.length > 0
        session[:account_message] = "Your account, #{disabled_user.login}, is not enabled for the following reason:\n#{disabled_user.reason_cannot_login.to_s}"
      else
        session[:account_message] = "Your account, #{disabled_user.login}, is no longer enabled. This may be due to inactivity."
      end
      session[:account_message] += "\n\nPlease see a staff member or email Technocrats if you need your account turned back on."
      render :update do |page|
        page.redirect_to(:controller => "sidebar_links", :action => "index")
      end
      return
    end
    self.current_user = User.authenticate(params[:login].to_s.strip, params[:password])
    if self.current_user
      self.current_user.will_not_updated_timestamps!
      self.current_user.last_logged_in = Date.today
      self.current_user.save
      mark_login_activity
    end
    flash[:error] = "invalid username/password" unless logged_in?
    rerender()
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    @current_user = nil
    session[:logout_message] = true
    redirect_to :controller => "sidebar_links", :action => "index"
  end

  protected

  def mark_login_activity
    if current_user
      session['worker_access_id'] = current_user.id
      session['worker_access_last'] = DateTime.now
    end
  end

  def rerender
    render :update do |page|
      if params[:goto]
        page.redirect_to(eval(params[:goto][:params]))
      else
        page.redirect_to("")
      end
    end
  end
end
