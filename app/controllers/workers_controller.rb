require 'barby'
require 'barby/outputter/rmagick_outputter'
require 'stringio'
require "prawn"

Prawn::Labels.types = {
  "Avery5390" => {
    "paper_size" => "LETTER",
    "top_margin" => 76.5,
    "bottom_margin" => 76.5,
    "left_margin" => 54,
    "right_margin" => 54,
    "columns" => 2,
    "rows" => 4,
    "column_gutter" => 0,
    "row_gutter" => 0,
    "vertical_text" => true
  }}

class WorkersController < ApplicationController
  protected
  def get_required_privileges
    a = super
    a << {:privileges => ['manage_workers']}
    a
  end
  public

  def index
    list
    render :action => 'list'
  end

  def badge
    if params[:contacts] or params[:contact]
      params[:contacts] ||= ""
      params[:contacts] += "," + params[:contact][:id] if params[:contact]
      @contacts = Contact.find_all_by_id(params[:contacts].split(/[, ]/).map(&:to_i)).sort_by(&:display_name)
      @workers = @contacts.select{|contact| contact.worker && (contact.volunteer_intern_title.nil? || contact.volunteer_intern_title.length == 0)}
    end
  end

  def modify_intern_title
    cid = params[:id]
    @contact = Contact.find(cid)
    @contact.volunteer_intern_title = params[:title]
    @contact.save
    render :update do |page|
      page.hide loading_indicator_id("intern_contact_#{cid}")
      page << 'window.location.href = "' + url_for(params[:returnopts]) + '"'
    end
  end

  def generate_badges
    badge
    tempf = `mktemp`
    orig_c = @contacts
    for_gen = []
    while orig_c.length > 0
      f_new = orig_c.shift(8)
      f_new += [Contact.new] until f_new.length == 8
      for_gen = f_new + ([nil] * 8)
    end
    Prawn::Labels.generate(tempf, for_gen, :type => "Avery5390") do |pdf, contact|
      if contact.nil?
        small = 8
        medium = 10
        large = 17
        pdf.bounding_box [25, pdf.bounds.height], :height => pdf.bounds.height, :width => pdf.bounds.width - 50 do
          pdf.text "\nThis ID badge belongs to FREE GEEK. If found please return to:\n\n\n", :size => small
          pdf.text "FREE GEEK\n", :size => large, :align => :center, :style => :bold # TODO: BOLD FIXME
          pdf.text "1731 SE 10th Ave\nPortland, OR 97214\n\n\n", :size => medium,  :align => :center
          pdf.text "503.232.9350\ninfo@freegeek.org\nwww.freegeek.org\n\n\n", :size => small, :align => :center
          pdf.text "FREE GEEK is generally open between the hours of 10:00 am and 6:00 pm Tuesdays through Saturdays. Due to potential closures, it is wise to call before coming.", :size => small
        end
      else
        unless contact.id.nil?
      top_h = 5 * pdf.bounds.height / 7.0
      low_h = 2 * pdf.bounds.height / 7.0
      name = contact.first_name + "\n" + contact.surname
      pdf.bounding_box [0, top_h + low_h], :height => top_h, :width => pdf.bounds.width do
        if @workers.include?(contact)
          one_w = 2 * pdf.bounds.width / 9.0
          two_w = 7 * pdf.bounds.width / 9.0
          pdf.bounding_box [0 + 5, pdf.bounds.height - 30], :width => one_w - 5, :height => pdf.bounds.height - 30 do
            pdf.y -= 2
            # 26, :style => [:bold]
            pdf.text "<b>STAFF</b>", :size => 28, :align => :center, :leading => -8, :inline_format => true
          end
          pdf.bounding_box [one_w, pdf.bounds.height], :width => two_w, :height => pdf.bounds.height do
            pic = RAILS_ROOT + "/public/images/workers/#{contact.worker.id}.png"
            pdf.image pic, :position => :center, :fit => [two_w - 10, pdf.bounds.height - 26] if File.exists?(pic)
            pdf.y -= 2
            pdf.bounding_box [0, 26], :width => two_w - 10, :height => 26 do
              pdf.text "Date issued: " + Date.today.strftime("%m/%d/%y"), :size => 8, :align => :right
            end
          end
        else
          pdf.text contact.intern_title, :size => 32, :height => pdf.bounds.height - 26, :valign => :center, :align => :center
          pdf.y -= (32 * 2)
          pdf.text "Date issued: " + Date.today.strftime("%m/%d/%y"), :size => 8, :align => :center
        end
      end
      pdf.bounding_box [0, low_h], :height => low_h, :width => pdf.bounds.width do
        one_w = 3 * pdf.bounds.width / 9.0
        two_w = 6 * pdf.bounds.width / 9.0
        pdf.bounding_box [0, pdf.bounds.height], :width => one_w, :height => pdf.bounds.height do
          pdf.image RAILS_ROOT + "/public/images/freegeeklogo.png", :fit => [pdf.bounds.width - 10, low_h], :vposition => :center, :position => :center
        end
        pdf.bounding_box [one_w, pdf.bounds.height], :width => two_w, :height => pdf.bounds.height do
          pdf.text name, :align => :center, :size => 10
          pdf.image StringIO.new((Barby::Code39.new(contact.id.to_s)).to_png(:margin => 0)), :height => 20, :width => two_w - 40, :position => :center
          pdf.y -= 5
          n = contact.id.to_s
          while n.length < 6
            n = "0" + n
          end
          n = "#" + n
          pdf.text n, :align => :center, :size => 10
        end
        end
      end
      #  pdf.stroke_color "000000"
      #  pdf.stroke_bounds # TODO: removeme
      end
    end
    sdata = File.open(tempf).read
    File.delete(tempf)
    send_data sdata, :filename => "badges.pdf",
                    :type => "application/pdf"
  end
  public

  def upload
    @worker = Worker.find_by_id(params[:id])
    dir = RAILS_ROOT + "/public/images/workers/"
    filename = dir + "#{@worker.id}.png"
    if !File.writable?(dir)
      flash[:error] = "Cannot write to #{filename}"
    else
      File.unlink(filename) if File.exists?(filename)
       File.open(filename, 'w') do |f|
        f.write(params[:picture].read)
      end
      flash[:notice] = "Uploaded new image for worker"
    end
    redirect_to params[:returnopts]
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @workers = Worker.paginate :order => 'name', :per_page => 20, :page => params[:page]
  end

  def show
    @worker = Worker.find(params[:id])
  end

  def new
    @worker = Worker.new
  end

  def create
    @worker = Worker.new(params[:worker])
    @worker.salaried = _parse_checkbox(params[:worker][:salaried])
    if @worker.save
      flash[:notice] = 'Worker was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @worker = Worker.find(params[:id])
    session["shift_return_to"] = "workers"
    session["shift_return_action"] = "edit"
    session["shift_return_id"] = @worker.id 
  end
  protected
  def _parse_checkbox(val)
    val = val.to_s
    if val == "1"
      return true
    elsif val == "0"
      return false
    else
      return nil
    end
  end
  public
  def update
    @worker = Worker.find(params[:id])
    @worker.salaried = _parse_checkbox(params[:worker][:salaried])
    if @worker.update_attributes(params[:worker])
      flash[:notice] = 'Worker was successfully updated.'
      redirect_to :action => 'show', :id => @worker
    else
      render :action => 'edit'
    end
  end

  def destroy
    Worker.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
