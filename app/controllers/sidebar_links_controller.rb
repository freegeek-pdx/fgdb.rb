class SidebarLinksController < ApplicationController
  layout :with_sidebar

  before_filter :authorized_only, :only => ["crash"]

  protected
  def authorized_only
    requires_role(:ADMIN)
  end

  public
  def crash
    f = File.join(RAILS_ROOT, "tmp", "crash", "crash." + params[:id])
    if !File.exist?(f)
      render :text => "oops, that crash id doesn't exist."
      return
    end
    @exception_data = JSON.parse(File.read(f))
  end

  def fgss_moved
    thing_moved("FGss", "spec_sheets")
  end

  def staffsched_moved
    thing_moved("Skedjulnator", "staffsched")
  end

  def library_moved
    thing_moved("Library", "library")
  end

  def thing_moved(thing, controller)
    @thing = thing
    if RAILS_ENV == "production"
      first_part = "data"
    else
      first_part = "dev:3000"
    end
    @url_ = "http://#{first_part}/#{controller}"
    render :action => "thing_moved", :layout => false
  end
end
