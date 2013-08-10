class SpecSheetsController < ApplicationController
  layout :with_sidebar
  protected

  before_filter :set_my_contact_context, :only => ["search"]
  def set_my_contact_context
    set_contact_context(ContactType.find_by_name('build'))
  end
  public

  helper :system
  include SystemHelper
  MY_VERSION=9

  def lookup_proc
    @proc_name = params[:proc]
    @tables = []
    @table_data = {}
    if @proc_name
      @tables = PricingData.lookup_proc(@proc_name)
      @tables.each do |a|
        tbl = a.first
        @table_data[tbl] = a.delete_at(2)
      end
    end
  end

  def sign_off
    if params[:cashier_code] && params[:cashier_code].length == 4
      u = User.find_by_cashier_code(params[:cashier_code])
      s = SpecSheet.find(params[:id])
      # if no admins, only people with actual build_instructor role, do this: u.privileges.include?(required_privileges("show/sign_off").flatten.first)
          # do not allow when users is the contact for the BT
      if u.contact_id != s.contact_id && u.has_privileges(required_privileges("show/sign_off").flatten.first)
        s.signed_off_by=(u)
        s.save!
      end
    end
    redirect_to :back
  end

  def check_compat
    # this is for old version compatibility
    # no real version 9 printme will get here

    render :xml => {:cli_compat => false, :ser_compat => true, :your_version => params[:version].to_i, :minimum_version => 9, :message => "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again.", :compat => false}
  end

  def original_dump; dump; end
  def cleaned_dump; dump; end
  def orig_dump; dump; end
  def clean_dump; dump; end

  def dump
    response.headers['content-type'] = "application/xml; charset=utf-8"
    thing = "lshw_output"
    if action_name().match(/clean/)
      thing = "cleaned_output"
    end
    if action_name().match(/orig/)
      thing = "original_output"
    end
    render :text => eval("SpecSheet.find(params[:id]).#{thing}")
  end

  def fix_contract
  end

  def fix_contract_edit
    @system = System.find_by_id(params[:system_id])
  end

  def fix_contract_save
    @system = System.find_by_id(params[:system][:id])
    @system.attributes = params[:system]
    @good = @system.save
  end

  def index
    search
  end

  def builder
    @contact = params[:contact] && Contact.find_by_id(params[:contact][:id].to_i)
    if !@contact
      flash[:error] = "Contact id ##{params[:contact].nil? ? "" : params[:contact][:id]} could not be found"
      redirect_to :action => "index"
      return
    end
    @contact_types = ContactType.builder_relevent
    @builder_tasks = @contact.builder_tasks.last_two_years
  end

  def system
    @main_system = System.find_by_id(params[:id].to_i)
    if flash[:error]
      @error = flash[:error]
    end
    if params[:id] && !@main_system
      @error = "System id ##{params[:id]} could not be found"
    end
  end

  def latest
    @main_system = System.find_by_id(params[:id].to_i)
    if !@main_system
      flash[:error] = "System id ##{params[:id]} could not be found"
      redirect_to :action => 'system'
      return
    end
    @system = @main_system.all_instances.select{|x| x.spec_sheets.length >= 1}.sort_by(&:created_at).last
    if !@system
      flash[:error] = "System id ##{params[:id]} has no spec sheets"
      redirect_to :action => 'system'
      return
    end
    redirect_to :action => "show", :controller => "spec_sheets", :id => @system.spec_sheets.sort_by(&:created_at).last.id
  end


  def search
    @error = params[:error]
    if !params[:conditions]
      params[:conditions] = {:created_at_enabled => "true"}
    end
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    if @conditions.contact_enabled
      if !has_required_privileges('/view_contact_name')
        return
      end
    end
    @reports = BuilderTask.paginate(:page => params[:page], :conditions => @conditions.conditions(BuilderTask), :order => "builder_tasks.created_at ASC", :per_page => 50, :include => [:spec_sheet => :system])
    render :action => "index"
  end

  def show
    begin
      @report = SpecSheet.find(params[:id])
    rescue => e
      flash[:error] = e.to_s
      redirect_to :action => "index"
      return
    end
    output=@report.lshw_output #only call db once
    if !@report.xml_is_good
      redirect_to(:action => "index", :error => "Invalid XML!")
      return
    end
    @system_parser = SystemParser.parse(output)
    @mistake_title = "Possible mistakes found in this report:"
    @mistakes = []
    if @report.contact
      if @report.contact.is_organization==true
        @mistakes << "The technician that you entered is an organization<br />(an organization should normally not be a technician)<br />Click Edit to change the technician"
      end
      type_expect = 'freekbox'
      if @report.type && @report.type.name == type_expect
        phash = @report.pricing_hash
        proc_expect = Default[type_expect + "_proc_expect"]
        ram_expect = Default[type_expect + "_ram_expect"]
        hd_min = Default[type_expect + "_hd_min"]
        hd_max = Default[type_expect + "_hd_max"]
        unless proc_expect.nil? || phash[:processor_product].match(proc_expect)
          @mistakes << "This system was built as a #{type_expect}, but has a #{phash[:processor_product]} processor instead of the expected #{proc_expect}"
        end
        if ram_expect && phash[:total_ram] != ram_expect
          @mistakes << "This system was built as a #{type_expect}, but has #{phash[:total_ram]} of memory instead of the expected #{ram_expect}"
        end
        if hd_min && phash[:hd_size_total].to_i < hd_min.to_i
          @mistakes << "This system was built as a #{type_expect}, but has #{phash[:hd_size_total]} of hard drive space, which is below the #{hd_min} minimum expected"
        end
        if hd_max && phash[:hd_size_total].to_i > hd_max.to_i
          @mistakes << "This system was built as a #{type_expect}, but has #{phash[:hd_size_total]} of hard drive space, which is above the #{hd_max} maximum expected"
        end
      end
    end
    @seen = []
    @seen_ser = []
    render :layout => 'fgss'
  end

  def new
    @report = SpecSheet.new
    @error=params[:error]
  end

  def edit
    @report = SpecSheet.find(params[:id])
  end

  protected

  def new_common_create_stuff(redirect_where_on_error, redirect_where_on_success)
    file = params[:report][:my_file]
    if !file.nil?
      if file == ""
        redirect_to(:action => redirect_where_on_error, :error => "lshw output needs to be attached")
        return
      end
      output = file.read
    end
    params[:report].delete(:my_file)
    params[:report][:lshw_output] = output
    params[:report][:old_id]=params[:report][:system_id]
    params[:report][:system_id] = 0
    @report = SpecSheet.new(params[:report])
    begin
      @report.save!
      if @report.xml_is_good
        redirect_to(:action => redirect_where_on_success, :id => @report.id)
      else
        redirect_to(:action => redirect_where_on_error, :error => "Invalid XML! Report id is #{@report.id}. Please report this bug.")
      end
    rescue
      redirect_to(:action => redirect_where_on_error, :error => "Could not save the database record: #{$!.to_s}")
    end
  end

  public

  def create
    new_common_create_stuff("new", "show")
  end

  def update
    @report = SpecSheet.find(params[:id])

    if @report.update_attributes(params[:report])
      redirect_to(:action=>"show", :id=>@report.id)
    else
      render :action => "edit"
    end
  end
end
