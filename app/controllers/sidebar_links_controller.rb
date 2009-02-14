class SidebarLinksController < ApplicationController
  layout :with_sidebar

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
    @url_ = "http://data/#{controller}"
    render :action => "thing_moved", :layout => false
  end
end
