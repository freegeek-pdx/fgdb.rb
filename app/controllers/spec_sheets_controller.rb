class SpecSheetsController < ApplicationController
  layout :with_sidebar

  helper :xml
  include XmlHelper
  MY_VERSION=9

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

  def search
    @error = params[:error]
    if !params[:conditions]
      params[:conditions] = {:created_at_enabled => "true"}
    end
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    if @conditions.contact_enabled
      if !requires_role('CONTACT_MANAGER')
        return
      end
    end
    @reports = SpecSheet.paginate(:page => params[:page], :conditions => @conditions.conditions(SpecSheet), :order => "created_at ASC", :per_page => 50)
    render :action => "index"
  end

  def show
    @report = SpecSheet.find(params[:id])
    output=@report.lshw_output #only call db once
    if !@report.xml_is_good
      redirect_to(:action => "index", :error => "Invalid XML!")
      return
    end
    @parser = load_xml(output)
    @mistake_title = "Things you might have done wrong: "
    @mistakes = []
    if !@report.notes || @report.notes == ""
      @mistakes << "You should include something in the notes<br />(anything out of the ordinary, the key to enter BIOS, etc)<br />Click Edit to add to the notes"
    end
    if @report.contact
      if @report.contact.is_organization==true
        @mistakes << "The technician that you entered is an organization<br />(an organization cannot be a technician)<br />Click Edit to change the technician"
      end
    end
    render :layout => 'fgss'
  end

  def new
    @report = SpecSheet.new
    @error=params[:error]
  end

  def edit
    @report = SpecSheet.find(params[:id])
  end

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
