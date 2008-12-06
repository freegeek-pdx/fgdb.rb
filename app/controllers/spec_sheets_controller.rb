class SpecSheetsController < ApplicationController
  layout :with_sidebar

  skip_before_filter :verify_authenticity_token, :only => ['xml_create']

  helper :xml
  include XmlHelper
  MY_VERSION=7

  def check_compat
    # always send compat as false so that old clients don't break

    # server hash works like this: server_versions[server_version_here] = [arr, of, compatible, client, versions]
    server_versions = Hash.new([])
    server_versions[1] = [1]      # I don't remember...but I know that it wouldn't have gotten to this point :)
    server_versions[2] = [2,3,4]  # really 2-4 are all compatible with all versions
    server_versions[3] = [3,4]    # force client upgrade. so of course old ones aren't compatible. (field renames)
    server_versions[4] = [4]      # yet another force client upgrade. (server version checking)
    server_versions[5] = [5]      # force upgrade. printme no longer fixes the xml.
    server_versions[6] = [6]      # see comment below.
    server_versions[7] = [7]      # see comment below.
    # client hash works like this: client_versions[client_version_here] = [arr, of, compatible, server, versions]
    client_versions = Hash.new([])
    client_versions[1] = [1]      # dunno
    client_versions[2] = [2,3]    # first one that makes it here. forced upgrade.
    client_versions[3] = [3]      # forced upgrade
    client_versions[4] = [3,4]    # forced upgrade
    client_versions[5] = [5]      # forced. the server needs to clean the xml now since printme isn't.
    client_versions[6] = [6,7]      # forced. add contracts support.
    client_versions[7] = [7]      # forced. fix contracts support.
    if !client_versions.include?(params[:version].to_i)
      render :xml => {:cli_compat => true, :ser_compat => false, :your_version => params[:version].to_i, :minimum_version => MY_VERSION, :message => "The server is incompatible. exiting.", :compat => false}
    elsif !params[:version] || params[:version].empty? || !server_versions[MY_VERSION].is_a?(Array) || !server_versions[MY_VERSION].include?(params[:version].to_i)
      render :xml => {:cli_compat => false, :ser_compat => true, :your_version => params[:version].to_i, :minimum_version => MY_VERSION, :message => "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again.", :compat => false}
    elsif !params[:version] || params[:version].empty? || !client_versions[params[:version].to_i].is_a?(Array) || !client_versions[params[:version].to_i].include?(MY_VERSION)
      render :xml => {:cli_compat => true, :ser_compat => false, :your_version => params[:version].to_i, :minimum_version => MY_VERSION, :message => "The server is incompatible. exiting.", :compat => false}
    else
      render :xml => {:cli_compat => true, :ser_compat => true, :compat => false}
    end
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

  def xml_index
    render :xml => {:error => params[:error]}
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
    @reports = SpecSheet.good.paginate(:page => params[:page] ? params[:page].to_i : 1, :conditions => @conditions.conditions(SpecSheet), :order => "created_at ASC", :per_page => 50)
    render :action => "index"
  end

  def xml_list_for_system
    @reports = SpecSheet.good.find_all_by_system_id(params[:id], :order => "id")
    render :xml => @reports
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

  def xml_show
    @report = SpecSheet.find(params[:id])
    render :xml => @report
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

  def xml_create
    params[:report]={
      :contact_id => params[:contact_id],
      :action_id => params[:action_id],
      :type_id => params[:type_id],
      :contract_id => params[:contract_id],
      :system_id => params[:system_id],
      :notes => params[:notes],
      :my_file => params[:my_file],
      :os => params[:os]
    }
    new_common_create_stuff("xml_index", "xml_show")
  end

  def update
    @report = SpecSheet.find(params[:id])

    if @report.update_attributes(params[:report])
      redirect_to(:action=>"show", :id=>@report.id)
    else
      render :action => "edit"
    end
  end

  def xml_system_show
    system = System.find_by_id(params[:id])
    if system
      render :xml => system
    else
      redirect_to(:action => "xml_index", :error => "That system does not exist!")
    end
  end

  def method_missing(symbol, *args)
    if (result = symbol.to_s.match(/(actions|types|contracts)_(xml_index)/))
      @property_type=result[1]
      @action=result[2]
      eval "self." + "properties_" + @action
    else
      raise NoMethodError
    end
  end

  def model
    @property_type.classify.constantize
  end

  def properties_xml_index
    @properties=model.usable
    render :xml => @properties
  end

  def properties_index
    @properties = model.usable
    render :action => "properties_" + @action
  end

  def properties_new
    @property = model.new
    render :action => "properties_" + @action
  end

  def properties_edit
    @property = model.find(params[:id])
    render :action  => "properties_" + @action
  end

  def properties_create
    @property = model.new(params[:property])

    if @property.save
      redirect_to(:action=>(@property_type + "_index"))
    else
      redirect_to(:action => (@property_type + "_new"), :error => "Could not save the database record")
    end
  end

  def properties_update
    @property = model.find(params[:id])

    if @property.update_attributes(params[:property])
      redirect_to(:action=>(@property_type + "_index"))
    else
      redirect_to(:action => (@property_type + "_new"), :error => "Could not save the database record")
    end
  end
end
