class SidebarLinksController < ApplicationController
  layout :with_sidebar

  def fgss_moved
    render :layout => false
  end

  def staffsched_moved
    render :layout => false
  end

  def library_moved
    render :layout => false
  end
end
