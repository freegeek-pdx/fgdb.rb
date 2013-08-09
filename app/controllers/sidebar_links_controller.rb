class SidebarLinksController < ApplicationController
  layout :with_sidebar

  protected

  public
  def homepage_index
    render :action => 'index'
  end

  def recent_crash
    d = File.join(RAILS_ROOT, "tmp", "crash")
    @page = params[:page] || 1
    @page = @page.to_i
    @first = `ls -t #{d} | head -#{30 * @page}`.split("\n")
    @first = @first[((@page - 1) * 30)..(@page * 30)]
    @first ||= []
    @first = @first.map{|x| x.split(".").last}
    @strs = {}
    for file in @first
      f = File.join(RAILS_ROOT, "tmp", "crash", "crash." + file)
      data = JSON.parse(File.read(f))
      @strs[file] = data
    end
  end

  def crash
    f = File.join(RAILS_ROOT, "tmp", "crash", "crash." + params[:id])
    if !File.exist?(f)
      render :text => "oops, that crash id doesn't exist."
      return
    end
    @exception_data = JSON.parse(File.read(f))
  end

  def fgss_moved
    render :layout => false
  end

  def staffsched_moved
    render :layout => false
  end

  def supplies_moved # or never existed here, actually..
    redirect_to "http://supplies.freegeek.org/"
  end

  def todo_moved
    redirect_to "http://todo.freegeek.org/"
  end

  def mail_moved
    redirect_to "https://mail.freegeek.org/"
  end

  def deadtrees_moved
    redirect_to "http://wiki.freegeek.org/index.php/Dead_trees"
  end
end
