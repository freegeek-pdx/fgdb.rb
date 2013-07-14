# Filters added to this controller will be run for all controllers in the application
# Likewise, all the methods added will be available for all controllers

module ActionController
  class Request
    def my_port
      return @fgdb_internal_port || @env["SERVER_PORT"].to_i
    end

    def port_string
      (my_port == standard_port) ? '' : ":#{my_port}"
    end

    def set_port(port_part)
      @host_with_port = nil
      @fgdb_internal_port = port_part.to_i
    end
  end
end

class ApplicationController < ActionController::Base
  protected
  def _parse_metadata_wo
    h = Hash.new([])
    cur = nil
    File.readlines(File.join(RAILS_ROOT, "config/rt_metadata.txt")).each do |line|
      line.strip!
      if line.match(/^== (.+) ==$/)
        cur = $1
        h[cur] = []
      else
        h[cur] << line.gsub(/^"(.+)"$/) do $1 end
      end
    end
    return h
  end

  def gencsv(*a)
    s = ""
    a = a.flatten
    CSV.generate_row(a, a.length, s)
    return s
  end

  def edit_footnote
    @date = params[:date]
    if params[:controller] == 'shifts'
      @schedule = params[:schedule_id]
      @footnote = ShiftFootnote.find_by_weekday_id_and_schedule_id(@date, @schedule) || ShiftFootnote.new(:weekday_id => @date, :schedule_id => @schedule)
    else
      @footnote = WorkShiftFootnote.find_by_date(@date) || WorkShiftFootnote.new(:date => @date)
    end
    render :update do |page|
      page.hide loading_indicator_id("footnote-#{params[:date]}")
      page.replace_html "fieldset-footnote-#{params[:date]}", :partial => "work_shifts/footnote_form"
    end
  end

  def save_footnote
    p = params[:controller] == 'shifts' ? params[:shift_footnote] : params[:work_shift_footnote]
    unless p
      redirect_to :action => 'edit_footnote'
      return
    end
    @date = p[:date]
    if params[:controller] == 'shifts'
      @schedule = p[:schedule_id]
      @footnote = ShiftFootnote.find_or_create_by_weekday_id_and_schedule_id(@date, @schedule)
      @vacs = []
    else
      @date = @date.to_date
      @vacs = Vacation.on_date(@date)
      @footnote = WorkShiftFootnote.find_or_create_by_date(@date)
    end
    @footnote.note = p[:note]
    if @footnote.note.strip.empty?
      @footnote.destroy if @footnote.id
    else
      @footnote.save
    end
    render :update do |page|
      page.hide loading_indicator_id("footnote-#{@date}")
      page.replace_html "fieldset-footnote-#{@date}", :partial => "work_shifts/footnote", :locals => {:display_link => true, :note => @footnote.note.strip.empty? ? nil : @footnote, :current_date => @date, :schedule_id => @schedule, :vacs => @vacs}
    end
  end

  before_filter :set_contact_context
  def set_contact_context(value = nil)
    if value.class == Array
      if value.length == 0
        value = nil
      else
        value = value.map(&:id) if value.length > 0 and value.first.class == ContactType
        value = value.join(",")
      end
    elsif value.class == ContactType
      value = value.id.to_s
    end
    Thread.current['contact-context'] = value
  end

  def determine_per_page
    session[:per_page] ||= 20
    session[:per_page] = params[:per_page] if params[:per_page]
    session[:per_page] = "500" if session[:per_page].to_i > 500
    return session[:per_page]
  end

  def my_apply_line_item_data(object, prefix, param = nil)
    input = params[param || prefix]
    association = object.send(prefix)
    seen = []
    if input
      for hash in input.values
        obj = nil
        if hash["id"] and hash["id"].to_i != 0
          obj = association.select{|x| x.id == (hash["id"].to_i)}.first
          seen << hash.delete("id").to_i
          obj.attributes_with_editable = hash
        else
          obj = association.build
          hash.delete("id")
          obj.attributes = hash
        end
      end
    end
    association.each{|x|
      unless x.id.nil? or seen.include?(x.id)
        x.mark_for_destruction
      end
    }
    association
  end

  def do_find_problems_report(klass, column, weeks, dates = [], mode = "ws", schedule_id = nil)
    @start_date, @end_date = dates
    opts = [@start_date, @end_date]
    if schedule_id
      opts << schedule_id
      opts << schedule_id
    end
    @conflicts = DB.exec(DB.prepare_sql("SELECT w1.#{column} AS date,workers.name AS worker,COALESCE(job1.name,w1.meeting_name,w1.#{mode == "ws" ? "kind" : "type"}) AS job_1,COALESCE(job2.name,w2.meeting_name,w2.#{mode == "ws" ? "kind" : "type"}) AS job_2,w1.id AS shift_1,w2.id AS shift_2 FROM #{klass.table_name} AS w1 INNER JOIN #{klass.table_name} AS w2 ON w1.worker_id = w2.worker_id AND w1.#{column} = w2.#{column} AND ((w1.start_time < w2.end_time AND w2.start_time < w1.end_time) OR (w1.start_time > w2.end_time AND w2.start_time > w1.end_time)) AND w1.id < w2.id AND w1.worker_id != 0 #{mode == "ws" ? "" : " AND w1.shift_date IS NULL AND w2.shift_date IS NULL AND (w1.ineffective_date IS NULL OR w1.ineffective_date >= '" + Date.today.to_s + "') AND (w2.ineffective_date IS NULL OR w2.ineffective_date >= '" + Date.today.to_s + "')"} LEFT JOIN jobs AS job1 ON job1.id = w1.job_id LEFT JOIN jobs AS job2 ON job2.id = w2.job_id LEFT JOIN workers ON w1.worker_id = workers.id WHERE w1.#{column} >= ? AND w1.#{column} <= ? #{schedule_id ? " AND w1.schedule_id = ? AND w2.schedule_id = ?" : ""} ORDER BY 1,2;", *opts)).to_a
    zopts = [@start_date, @end_date]
    zopts << schedule_id if schedule_id
    @unassigned = DB.exec(DB.prepare_sql("SELECT w1.#{column} AS date,COALESCE(job1.name,w1.meeting_name,w1.#{mode == "ws" ? "kind" : "type"}) || case training when 't' then ' (Training)' else '' end AS job FROM #{klass.table_name} AS w1 LEFT JOIN jobs AS job1 ON job1.id = w1.job_id WHERE #{klass == Shift ? "type NOT LIKE 'Meeting' AND" : ""} w1.worker_id = 0 #{mode == "ws" ? "" : " AND w1.shift_date IS NULL  AND (w1.ineffective_date IS NULL OR w1.ineffective_date >= '" + Date.today.to_s + "')"} AND w1.#{column} >= ? AND w1.#{column} <= ? #{schedule_id ? " AND w1.schedule_id = ?" : ""} ORDER BY 1,2;", *zopts)).to_a
    @all_dates = (dates.first..dates.last).to_a.select{|x| Weekday.find_by_id(mode == "ws" ? x.wday : x).is_open}
    @jobs = Job.find_all_by_fully_covered(true)
    copts = [@jobs.map{|x| x.id}, @start_date, @end_date]
    copts << schedule_id if schedule_id
    all_shifts = klass.find(:all, :conditions => ["#{mode == "ws" ? "" : " shift_date IS NULL AND (ineffective_date IS NULL OR ineffective_date >= '" + Date.today.to_s + "') AND "} (training = 'f' OR training IS NULL) AND job_id IN (?) AND #{column} >= ? AND #{column} <= ? #{schedule_id ? ' AND schedule_id = ?' : ''}", *copts])
    weekday_times = {}
    Weekday.find(:all).each do |w|
      weekday_times[w.id] = [w.open_time, w.close_time]
    end
    @shift_gap_hash = {}
    @shift_gap_found_hash = {}
    @jobs.each{|x|
      @shift_gap_hash[x.id] = {}
      @shift_gap_found_hash[x.id] = {}

      weekdays = {}
      Weekday.find(:all).each{|w|
        weekdays[w.id] = Shift.find(:all, :conditions => ["shift_date IS NULL AND (ineffective_date IS NULL OR ineffective_date >= ?) AND (training = 'f' OR training IS NULL) AND job_id IN (?) AND weekday_id = ? AND schedule_id = ?", Date.today.to_s, [x.id], w.id, Schedule.reference_from ? Schedule.reference_from.id : -1]).map{|y| [y.start_time, y.end_time]}
      }
      @all_dates.each{|d|
        @shift_gap_hash[x.id][d] = weekdays[mode == "ws" ? d.wday : d].dup
        @shift_gap_found_hash[x.id][d] = []
      }
    }
    all_shifts.each{|x|
      k = x.send(column.to_sym)
      @shift_gap_found_hash[x.job_id][k].push([x.start_time, x.end_time]) if @shift_gap_hash[x.job_id].keys.include?(k)
    }
    @shift_gap_hash.keys.each{|x|
      @shift_gap_hash[x].keys.each{|d|
        remove_these = @shift_gap_found_hash[x][d]
        while remove_these.length > 0
          found = remove_these.pop
          remaining = []
          @shift_gap_hash[x][d].each do |expected|
            if found
              left = klass.range_math(found, expected)
              holes = klass.range_math(expected, found)
              found = left.pop
              left.each do |f|
                remove_these.push(f)
              end
              holes.each do |h|
                remaining << h
              end
            else
              remaining << expected
            end
          end
          @shift_gap_hash[x][d] = remaining
        end
      }
    }
    @workers_week_hash = {}
    @workers_day_hash = {}
    @workers = []
    @workers_h = {}
    dopts = [@weeks.first, (@weeks.last+6)]
    if schedule_id
      dopts << schedule_id
    end
    all_scheduled = klass.find(:all, :conditions => ["#{mode == "ws" ? "" : " shift_date IS NULL AND (ineffective_date IS NULL OR ineffective_date >= '" + Date.today.to_s + "') AND "} #{column} >= ? AND #{column} <= ? AND #{mode == "ws" ? "kind" : "type"} NOT LIKE 'Unavailability' #{schedule_id ? ' AND schedule_id = ?': ''}", *dopts], :order => "#{column} ASC")
    cur_week = @weeks.first
    all_scheduled.each{|w|
      if !@workers.include?(w.worker)
        @workers << w.worker
        @workers_h[w.worker_id] = w.worker
        @workers_week_hash[w.worker_id] = {}
        @weeks.each{|week|
          @workers_week_hash[w.worker_id][week] = 0.0
        }
        @workers_day_hash[w.worker_id] = {}
        (@all_dates).each{|day|
          @workers_day_hash[w.worker_id][day] = [weekday_times[mode == "ws" ? day.wday : day]]
        }
      end
      if w.send(column.to_sym) > (cur_week + 6)
        cur_week += 7
      end
      @workers_week_hash[w.worker_id][cur_week] += ((w.end_time - w.start_time)/3600.0)
      if @all_dates.include?(w.send(column.to_sym))
        @workers_day_hash[w.worker_id][w.send(column.to_sym)] << [w.start_time, w.end_time]
      end
    }
    @workers_day_hash.keys.each{|w|
      @workers_day_hash[w].keys.each{|d|
        @workers_day_hash[w][d] = klass.range_math(*@workers_day_hash[w][d])
      }
    }
  end

  def update_skedjulnator_access_time
    current_user.update_skedjulnator_access_time
  end

  def redirect_skedj(referer, anchor)
    redirect_to(sked_url(referer, anchor))
  end

  def sked_url(referer, anchor)
    (referer ? (referer + "#" + anchor) : ({:action => "index"}))
  end

  include AuthenticatedSystem
  layout "application"
  helper :cashiers
  helper :conditions
  helper :sidebar
  helper :line_item
  include LineItemHelper

  def _civicrm_sync
    ret = ProcessorDaemon.add_to(params[:controller], params[:id], "civicrm")
    render :text => (ret ? "ok" : "notok")
  end

  def hours_val(cp)
    mins = cp["minutes"].to_i
    hours = cp["hours"].to_i
    sign = (cp["sign"] == "-") ? -1 : 1
    return 60 * (mins + (hours * 60)) * sign # secs
  end

  rescue_from 'Exception', :with => :process_exception

  def rescue_as_normal
    return false
  end

  def do_volskedj_generate(cname)
    gconditions = Conditions.new
    unless params[:gconditions]
      redirect_to :action => "index"
      return
    end
    gconditions.apply_conditions(params[:gconditions])
    params[:conditions] = params[:gconditions].dup
    begin
      startd, endd = Date.parse(params[:date_range][:start_date]), Date.parse(params[:date_range][:end_date])
    rescue
      flash[:error] = "Generate error: A valid date range was not given"
      redirect_to :back
      return
    end

    do_shifts = params[:date_range][:do_shifts] == "1"
    do_resources = params[:date_range][:do_resources] == "1"

    @start_date = startd
    @end_date = endd
    @do_resources = do_resources
    @do_shifts = do_shifts

    in_error = false

    overwrite_matches = []
    overwrite_matches += VolunteerDefaultShift.find_conflicts(startd, endd, gconditions) if do_shifts
    overwrite_matches += ResourcesVolunteerDefaultEvent.find_conflicts(startd, endd, gconditions) if do_resources


    if overwrite_matches.length > 0
      @force_generate = true
      @skedj_error = "There are existing scheduled items that will be DESTROYED and overwritten by this generate. Any volunteers who have signed up for or changed shifts will be reverted. If you know what you are doing, you can continue by submitting your request again below to force overwriting the data."
      @events = overwrite_matches.map{|x| x.volunteer_event}.uniq.sort_by(&:date).map{|x| [x.date, x.description].join(" ")}
      if params[:date_range][:force_generate] != "1"
        in_error = true
      end
    end

    skip_these = []
    destroy_these = []
    if do_shifts
      @conflicting_assignments = VolunteerDefaultShift.find_conflicting_assignments(startd, endd, gconditions)
      @conflicting_assignments_responses = (params[:conflicting_assignments_responses] || {})
      @conflicting_assignments.each{|c|
        resp = @conflicting_assignments_responses["assignment_conflict_#{c[1].id}_#{c.first}"].to_s
        if resp == "leave"
          skip_these << c
        elsif resp == "replace"
          destroy_these << c
        end
      }
      # we want to still display the choices for all conflicts, even if the user has already chosen for some of them
      if (@conflicting_assignments - (skip_these + destroy_these)).length > 0
        in_error = true
        if !@skedj_error
          @skedj_error = "Some conflicts prevented the generate you requested, see below to resolve the issue."
        end
      end
    end

    if in_error
      index
      return
    end

    if do_shifts
      overwrite_matches.each{|y| y.destroy}
      destroy_these.each{|x| x.last.each{|y| y.destroy}}
      VolunteerDefaultShift.generate(startd, endd, gconditions, skip_these.map{|x| x[1].id})
    end
    if do_resources
      ResourcesVolunteerDefaultEvent.generate(startd, endd, gconditions)
    end

    redirect_to :controller => cname, :action => "index", :conditions => params[:gconditions].merge({:date_start_date => params[:date_range][:start_date], :date_end_date => params[:date_range][:end_date], :date_date_type => "arbitrary", :date_enabled => "true"})
  end

  def process_exception(exception)
    authorize
    set_cashier
    if rescue_as_normal
      ret = rescue_action(exception)
    else
      ret = rescue_action_locally(exception)
    end
    if request and request.xhr?
      response.content_type = Mime::JS
    end
    return ret
  end

  def rescues_path(thing)
    if rescue_as_normal
      return super(thing)
    elsif request and request.xhr?
      return "app/views/sidebar_links/error.rjs"
    elsif thing == "layout"
      return "app/views/layouts/application.html.erb"
    else
      return "app/views/sidebar_links/error.html.erb"
    end
  end

  before_filter :set_correct_server_port
  def set_correct_server_port
    orig_host = request.env["HTTP_FGDB_PROXY_HTTP_HOST"]
    return if orig_host.nil?
    host_part, port_part = orig_host.split(":")
    return if port_part.nil?
    request.set_port(port_part)
    return true
  end

=begin
    protect_from_forgery
    post_list = ["create", "update", "xml_create"]
    ajax_post_list = ["new", "edit", "component_update", "update_display_area"]
    verify :method => :get, :except => post_list + ajax_post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
    verify :method => :post, :xhr => true, :only => post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
    verify :method => :post, :only => post_list, :redirect_to => {:controller => "sidebar_links", :action => "index"}
=end

  before_filter :authorize

  before_filter :set_cashier

  def set_cashier
    uid = _set_cashier(params)
    if uid && (u = User.find_by_shared_and_cashier_code(false, uid.to_i))
      Thread.current['cashier'] = u
      u.will_not_updated_timestamps!
      u.last_logged_in = Date.today
      u.save
    else
      Thread.current['cashier'] = nil
      logger.warn "Cashier not found" # die better
    end
  end

  def _set_cashier(hash)
    return hash["cashier_code"] if hash.keys.include?("cashier_code")
    for i in hash.values.select{|x| x.class == Hash}
      x = _set_cashier(hash)
      return x if !x.nil?
    end
    return nil
  end

  def current_cashier
    Thread.current['cashier']
  end

  def with_sidebar
    "with_sidebar.html.erb"
  end

  def authorize
    x = current_user()
    if x.kind_of?(User)
      @current_user = x
    else
      @current_user = nil
    end
    Thread.current['user'] = @current_user
  end

  def redirect_to_with_back_magic(*opts)
    if opts[0] == :back
      if !request.headers["Referer"]
        opts[0] = "/"
        flash[:jsalert] = "Your request completed successfully, but was unable to determine your previous location, so you have been sent here instead." if !flash[:jsalert]
      end
    end
    redirect_to_without_back_magic(*opts)
  end
  alias_method_chain :redirect_to, :back_magic

  def required_privileges(action)
    requires = []
    base_action = action.split("/").first
    if base_action == "" and params
      base_action = params[:action]
    end
    all = []
    get_required_privileges.each{|x|
      all << [x[:only], x[:except]]
      if (x[:only].nil? || x[:only].include?(action) || x[:only].include?(base_action)) && (x[:except].nil? || !(x[:except].include?(action) || x[:except].include?(base_action)))
        requires << x[:privileges]
      end
    }
    all = all.flatten.uniq
    if !all.include?(action)
#      puts "WARNING: action #{action}, for which the list of required privileges has been requested, is apparently unknown to the privilege system"
      nil
    end
    requires.each{|x| x.flatten!}
    requires
  end

  helper_method :has_required_privileges

  def self.has_required_privileges(action)
    self.new.has_required_privileges(action)
  end

  def has_required_privileges(action)
    required_privileges(action).each{|x|
      if !has_privileges(x)
        return false
      end
    }
    return true
  end

  def self.sb_has_required_privileges(action)
    self.new.send(:_internal_sb_has_required_privileges, action)
  end

  def _internal_sb_has_required_privileges(action) # TODO: should this be self.has_required_privileges? so Controller.has_required does one thing, while Controller.new.has_required does the other
    required_privileges(action).each{|x|
      if !has_privileges(_privis_to_out_of_page(x))
        return false
      end
    }
    return true
  end

  def get_required_privileges
    a = []
    a << {:only => ["/contact_condition_everybody"], :privileges => ['manage_contacts']}
    a << {:only => ["/admin_inventory_features"], :privileges => ['role_admin']}
    return a
  end

  def _privis_to_out_of_page(privs)
    mappings = {"contact_nil" => "has_contact", "contact_" => "has_contact"}
    res = privs.map{|x|
      mappings[x] || x
    }
#    puts res.inspect
    return res
  end

  before_filter :authorize_to_required_privileges

  def authorize_to_required_privileges
    if has_required_privileges(params[:action])
      return true
    else
      session[:unauthorized_error] = true
      session[:unauthorized_params] = params.inspect
      redirect_to :controller => 'sidebar_links', :action => 'homepage_index'
      return false
    end
  end

  # start auth junk

  def has_privileges(*privs)
    User.current_user.has_privileges(*privs)
  end

  # end auth junk

  before_filter :fix_null_date

  def fix_this_null_date (c1, c2)
    if params[c1]
      if params[c1][c2]
        if params[c1][c2].empty?
          params[c1][c2] = nil
        end
      end
    end
  end

  def fix_null_date
    return if !([:volunteer_default_shifts, :volunteer_shifts, :customizations, :holidays, :jobs, :meetings, :rr_items, :rr_sets, :schedules, :shifts, :standard_shifts, :unavailabilities, :vacations, :weekdays, :workers, :worker_types, :work_shifts].map{|x| x.to_s}.include?(params[:controller]) && ["update","create"].include?(params[:action]))
    # fields to check. these are date fields that allow NULL
    # values in the database. the dhtml-calendar plugin passes an
    # empty string when the date is left blank, this turns into
    # an arbitrary and unwanted date rather than a NULL. fix
    # these by explicitly setting these values to nil. 
    fix_this_null_date(:volunteer_default_shift, :ineffective_at)
    fix_this_null_date(:volunteer_default_shift, :effective_at)
    fix_this_null_date(:volunteer_shift, :date)
    fix_this_null_date(:holiday, :holiday_date)
    fix_this_null_date(:meeting, :meeting_date)
    fix_this_null_date(:meeting, :effective_date)
    fix_this_null_date(:meeting, :ineffective_date)
    fix_this_null_date(:rr_set, :effective_date)
    fix_this_null_date(:rr_set, :ineffective_date)
    fix_this_null_date(:schedule, :effective_date)
    fix_this_null_date(:schedule, :ineffective_date)
    fix_this_null_date(:shift, :shift_date)
    fix_this_null_date(:shift, :effective_date)
    fix_this_null_date(:shift, :ineffective_date)
    fix_this_null_date(:standard_shift, :shift_date)
    fix_this_null_date(:unavailability, :effective_date)
    fix_this_null_date(:unavailability, :ineffective_date)
    fix_this_null_date(:vacation, :effective_date)
    fix_this_null_date(:vacation, :ineffective_date)
    fix_this_null_date(:work_shift, :shift_date)
    fix_this_null_date(:work_shift, :effective_date)
    fix_this_null_date(:work_shift, :ineffective_date)
    fix_this_null_date(:worker, :effective_date)
    fix_this_null_date(:worker, :ineffective_date)
  end
end
