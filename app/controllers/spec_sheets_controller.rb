class SpecSheetsController < ApplicationController
  layout :with_sidebar

  helper :xml
  include XmlHelper
  MINIMUM_COMPAT_VERSION=3

  def check_compat
    if !params[:version] || params[:version].empty? || params[:version].to_i < MINIMUM_COMPAT_VERSION
      render :xml => {:compat => false, :your_version => params[:version].to_i, :minimum_version => MINIMUM_COMPAT_VERSION, :message => "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again."}
    else
      render :xml => {:compat => true}
    end
  end

  def dump
    response.headers['content-type'] = "application/xml; charset=utf-8"
    render :text => SpecSheet.find(params[:id]).lshw_output
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
      if !requires_role('ROLE_CONTACT_MANAGER')
        return
      end
    end
    @reports = SpecSheet.find(:all, :conditions => @conditions.conditions(SpecSheet))
    render :action => "index"
  end

  def xml_list_for_system
    @reports = SpecSheet.find_all_by_system_id(params[:id], :order => "id")
    render :xml => @reports
  end

  def show
    @report = SpecSheet.find(params[:id])
    output=@report.lshw_output #only call db once
    if !(output) || output == ""
      redirect_to(:action => "index", :error => "There is no lshw output for that report!")
      return
    end
    if !load_xml(output)
      redirect_to(:action => "index", :error => "Invalid XML!")
      return
    end
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
    if file != ""
      output = file.read
    end
    if output == nil || output.empty?
      redirect_to(:action => redirect_where_on_error, :error => "The posted lshw output was empty!")
      return
    end
    if !load_xml(output)
      redirect_to(:action => redirect_where_on_error, :error => "Invalid XML!")
      return
    end
    # If we pass in the file descriptor to ActiveRecord, the file is already at the end so it will read an empty string
    params[:report].delete(:my_file)
    params[:report][:lshw_output] = output
    params[:report][:old_id]=params[:report][:system_id]
    params[:report][:system_id] = 0
    @report = SpecSheet.new(params[:report])
    begin
      @report.save!
      redirect_to(:action => redirect_where_on_success, :id => @report.id)
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
    if (result = symbol.to_s.match(/(actions|types)_(xml_index)/))
      @property_type=result[1]
      @action=result[2]
      eval "self." + "properties_" + @action
    else
      super
    end
  end

  def model
    @property_type.classify.constantize
  end

  def properties_xml_index
    @properties=model.find(:all, :order => "id")
    render :xml => @properties
  end

  def properties_index
    @properties = model.find(:all, :order => "id")
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
