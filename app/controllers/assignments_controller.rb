class AssignmentsController < ApplicationController
  protected
  before_filter :set_my_contact_context, :only => ["search"]
  def set_my_contact_context
    set_contact_context(ContactType.find_by_name('volunteer'))
  end

  public

  def noshows
    @attendance_types = AttendanceType.find(:all).sort_by(&:id)
    @noshow_attendance_types = [AttendanceType.find_by_name('no call no show').id]
    @arrived_attendance_types = (AttendanceType.find_all_by_cancelled(nil) + AttendanceType.find_all_by_cancelled(false)).map(&:id)
    @sort_by = :noshow
    @percent = 0
    @count = 1
  end

  def noshows_report
    @date1 = params[:start_date]
    @date2 = params[:end_date]

    @attendance_types = AttendanceType.find(:all).sort_by(&:id)
    @noshow_attendance_types = params[:noshow_attendance_types].map(&:to_i)
    @arrived_attendance_types = params[:arrived_attendance_types].map(&:to_i)

    @percent = params[:percent]
    @count = params[:count]

    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])

    baseopts = [@date1, @date2]
    conds = "volunteer_events.date >= ? AND volunteer_events.date <= ? AND attendance_type_id IN (?)"
    full_conds = "attendance_type_id IN (?)"

    add = @conditions.conditions(Assignment)
    if add[0] != "assignments.id = -1"
      conds += " AND " + add[0]
    end
    add.shift

    fullopts = [@noshow_attendance_types]
    fullgoodopts = [@arrived_attendance_types]
    opts = baseopts + fullopts + add
    goodopts = baseopts + fullgoodopts + add

    @noshows = DB.exec(["SELECT assignments.contact_id AS contact_id, COUNT(*) FROM assignments JOIN volunteer_shifts ON volunteer_shift_id=volunteer_shifts.id JOIN volunteer_events ON volunteer_event_id=volunteer_events.id WHERE #{conds} GROUP BY 1 ORDER BY 2 DESC;", *opts]).to_a

    @contact_ids = @noshows.map{|x| x["contact_id"]}
    goodopts << @contact_ids
    fullopts << @contact_ids
    fullgoodopts << @contact_ids

    @arrived = DB.exec(["SELECT assignments.contact_id AS contact_id, COUNT(*) FROM assignments JOIN volunteer_shifts ON volunteer_shift_id=volunteer_shifts.id JOIN volunteer_events ON volunteer_event_id=volunteer_events.id WHERE #{conds} AND contact_id IN (?) GROUP BY 1 ORDER BY 2 DESC;", *goodopts]).to_a
    @fullnoshows = DB.exec(["SELECT assignments.contact_id AS contact_id, COUNT(*) FROM assignments WHERE #{full_conds} AND contact_id IN (?) GROUP BY 1 ORDER BY 2 DESC;", *fullopts]).to_a
    @fullarrived = DB.exec(["SELECT assignments.contact_id AS contact_id, COUNT(*) FROM assignments WHERE #{full_conds} AND contact_id IN (?) GROUP BY 1 ORDER BY 2 DESC;", *fullgoodopts]).to_a

    # build @contacts hash and @list of contacts
    @contacts = {}
    @list = []
    @noshows.each do |noshow|
      @list << noshow["contact_id"] if noshow["contact_id"]
      @contacts[noshow["contact_id"]] = {:contact_id => noshow["contact_id"].to_i, :noshow => noshow["count"].to_i, :contact => Contact.find_by_id(noshow["contact_id"]), :arrived => 0, :fullnoshows => 0, :fullarrived => 0, :shifts => []}
    end
    @arrived.each do |noshow|
      @contacts[noshow["contact_id"]][:arrived] = noshow["count"].to_i
    end
    @fullnoshows.each do |noshow|
      @contacts[noshow["contact_id"]][:fullnoshows] = noshow["count"].to_i
    end
    @fullarrived.each do |noshow|
      @contacts[noshow["contact_id"]][:fullarrived] = noshow["count"].to_i
    end

    # calculate percentages
    @list.each do |cid|
      c = @contacts[cid]

      n = c[:noshow]
      c[:noshow_percentage] = 100.0 * n / (n + c[:arrived])

      n = c[:fullnoshows]
      c[:fullnoshows_percentage] = 100.0 * n / (n + c[:fullarrived])
    end

    # filter the results
    if params[:count].to_f > 1.0
      f = params[:count].to_f
      @list = @list.select{|x| @contacts[x][:noshow] >= f}
    end
    if params[:percent].to_f > 0.0
      f = params[:percent].to_f
      @list = @list.select{|x| @contacts[x][:noshow_percentage] >= f}
    end

    @assignments = Assignment.find(:all, :conditions => [conds, opts].flatten, :include => [:volunteer_shift => [:volunteer_event]], :order => 'volunteer_events.date ASC')
    @assignments.each do |a|
      @contacts[a.contact_id.to_s][:shifts] << a.description if a.contact_id
    end

    @sort_by = (params[:sort_by] || "noshow").to_sym
    @list = @list.sort_by{|x| @contacts[x][@sort_by]}.reverse
  end

  layout :with_sidebar

  helper :skedjul

  def builder_history
    begin
      a = Assignment.find(params[:id])
    rescue
      flash[:jsalert] = "Assignment was deleted before the status sheet could be loaded."
      redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_shift.date_anchor : "")
      return
    end
    if a.contact_id
      redirect_to :action => "builder", :controller => "spec_sheets", :contact => {:id => a.contact_id}
    else
      flash[:jsalert] = "Assignment does not have a contact associated."
      redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_shift.date_anchor : "")
    end
  end

  def notes
    a = Assignment.find_by_id(params[:id])
    c = nil
    if !(a.nil? or a.contact_id.nil?)
      c = a.contact
    end
    str = c.nil? ? "No contact found" : "Contact ##{c.id} notes:\n#{c.notes}".gsub(/\n/, "<br/>")
    if a.has_own_notes
      str += "<hr />Assignment notes:<br />#{a.notes}"
    end
    render :update do |page|
      page.hide loading_indicator_id("skedjul_#{params[:skedjul_loading_indicator_id]}_loading")
      page << "show_message(#{str.to_json});"
    end
  end

  def view
    params["opts"] = {:presentation_mode => "Display"}
    @readonly = true
    index
  end

  def open
    begin
      a = Assignment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "Assignment was deleted before it could be marked as open"
    end
    a.closed = false if a
    if a && a.valid?
      a.save!
    else
      flash[:jsalert] = "An unknown error prevented the shift from being marked open" if flash[:jsalert].nil?
    end

    redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_shift.date_anchor : "")
  end

  def close
    begin
      a = Assignment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "Assignment was deleted before it could be marked as closed"
    end
    if a && a.contact_id
      flash[:jsalert] = "Assignment which has a contact cannot be marked as closed"
    end
    a.closed = true if a
    if a && a.valid?
      a.save!
    else
      flash[:jsalert] = "An unknown error prevented the shift from being marked closed" if flash[:jsalert].nil?
    end
    redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_shift.date_anchor : "")
  end

private
def create_skedjul
      my_sort_prepend = params[:conditions][:sked_enabled] == "true" ? "(SELECT position FROM rosters_skeds WHERE sked_id = #{params[:conditions][:sked_id]} AND roster_id = volunteer_shifts.roster_id), " : "volunteer_shifts.roster_id, "
      links = [[:arrived, :link, :contact_id_and_by_today], [:reassign, :function, :contact_id], [:split, :remote, :contact_id], [:notes, :remote, :has_notes], [:edit, :link], [:builder_history, :link, :if_builder_assigned], [:copy, :link, :volshift_stuck], [:close, :link, :not_assigned, :x], [:open, :link, :closed], [:attendance, :remote, :contact_id, :t]]
    @skedj = Skedjul.new({
      :conditions => ['contact', "sked", "roster", "volunteer_task_type", "needs_checkin", "assigned", "weekday"],
      :date_range_condition => "date",
      :forced_condition => "cancelled",
                           :maximum_date => "newc = skedj.conditions.dup; newc.date_enabled = false; VolunteerEvent.maximum(:date, :conditions => newc.conditions(Assignment), :joins => 'INNER JOIN \"volunteer_shifts\" ON volunteer_shifts.volunteer_event_id = volunteer_events.id INNER JOIN \"assignments\" ON assignments.volunteer_shift_id = volunteer_shifts.id LEFT OUTER JOIN \"attendance_types\" ON \"attendance_types\".id = \"assignments\".attendance_type_id')",

      :block_method_name => "volunteer_shifts.volunteer_events.date",
      :block_anchor => 'volunteer_shifts.date_anchor',
      :block_method_display => "volunteer_shifts.date_display",
      :block_start_time => "volunteer_shifts.weekdays.start_time",
      :block_end_time => "volunteer_shifts.weekdays.end_time",
      :default_view => "by_slot",
                           :table_head_partial => "assignments/multi_edit",
                           :cell_onclick => "selection_toggle",

                           :views => {
                             :by_slot =>
                             { :left_unique_value => "volunteer_shifts.left_unique_value", # model
                               :left_sort_value => "#{my_sort_prepend}(coalesce(volunteer_task_types.description, volunteer_events.description)), volunteer_shifts.slot_number",
                               :left_method_name => "volunteer_shifts.left_method_name",
                               :title_between => 'volunteer_shifts.rosters.name',
                               :break_between_difference => "assignments.slot_type_desc",

                               :thing_start_time => "assignments.start_time",
                               :thing_end_time => "assignments.end_time",
                               :thing_table_name => "assignments",
                               :thing_description => "time_range_s,display_name",
                               :thing_link_id => "assignments.id",
                               :thing_links => links,
                             },

                             :call_list =>
                             { :left_unique_value => "volunteer_shifts.left_unique_value", # model
                               :left_sort_value => "(coalesce(volunteer_task_types.description, volunteer_events.description)), volunteer_shifts.slot_number",
                               :left_method_name => "volunteer_shifts.left_method_name",
                               :break_between_difference => "assignments.slot_type_desc",

                               :thing_start_time => "assignments.start_time",
                               :thing_end_time => "assignments.end_time",
                               :thing_table_name => "assignments",
                               :thing_description => "time_range_s,display_name,display_call_status,display_phone_numbers",
                               :thing_link_id => "assignments.id",
                               :thing_links => links,
                             },

                             :by_worker =>
                             { :left_unique_value => "assignments.contact_id",
                               :left_sort_value => "assignments.contacts.sort_name",
                               :left_method_name => "assignments.contact_display",
                               :left_table_name => "contacts",
#                               :left_link_action => "assignments",
#                               :left_link_id => "contacts.id", # TODO?

                               :thing_start_time => "assignments.start_time",
                               :thing_end_time => "assignments.end_time",
                               :thing_table_name => "assignments",
                               :thing_description => "time_range_s,volunteer_shifts.left_method_name",
                               :thing_link_id => "assignments.id",
                               :thing_links => links,
                             }
                           },

      }, params)
    @opts = @skedj.opts
    @conditions = @skedj.conditions
      @page_title = @conditions.skedj_to_s("after", false, ["cancelled"])
      @page_title = "All schedules" if @page_title.length == 0

    @skedj.find({:conditions => @skedj.where_clause, :include => [:attendance_type => [], :volunteer_shift => [:volunteer_task_type, :volunteer_event, :roster], :contact => [], :contact_volunteer_task_type_count => []]})
end
public

  def index
    @multi_enabled = true
    if params[:conditions]

      create_skedjul
      render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "index",  :layout => :with_sidebar
    end
  end

  def turbo
    @multi_enabled = true
    if params[:conditions]
      create_skedjul
      render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "turbo",  :layout => :with_sidebar
    end
  end

  def reassign
    assigned, available = params[:id].split(",")

    Assignment.transaction do
    # readonly
    begin
      @assigned_orig = Assignment.find(assigned)
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "The assignment (##{assigned}) seems to have disappeared. It is possible somebody else has modified or deleted it."
    end
    begin
      @available = Assignment.find(available)
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "The assignment (##{available}) seems to have disappeared. It is possible somebody else has modified or deleted it."
    end

    if @assigned_orig && @available
    if @available.volunteer_shift.stuck_to_assignment or @assigned_orig.volunteer_shift.stuck_to_assignment
      flash[:jsalert] = "Cannot reassign an intern shift, please either delete the intern shift or assign it to somebody else"
    else
      cid = @available.contact_id
      if cid
        @available.contact_id = nil
        @available.save
      end

      # for write
      begin
        @assigned = Assignment.find(assigned)
      rescue ActiveRecord::RecordNotFound
        flash[:jsalert] = "The assignment (##{assigned}) seems to have disappeared. It is possible somebody else has modified or deleted it."
      end
      if @assigned
        @new = Assignment.new # available

        # do it
        @assigned.volunteer_shift_id = @available.volunteer_shift_id
        @assigned.start_time = @available.start_time if (@assigned.start_time < @available.start_time) or (@assigned.start_time >= @available.end_time)
        @assigned.end_time = @available.end_time if (@assigned.end_time > @available.end_time) or (@assigned.end_time <= @available.start_time)

        @new.start_time = @available.start_time
        @new.start_time = @assigned_orig.start_time if (@new.start_time < @assigned_orig.start_time) or (@new.start_time >= @assigned_orig.start_time)
        @new.end_time = @available.start_time
        @new.end_time = @assigned_orig.end_time if (@new.end_time > @assigned_orig.end_time) or (@new.end_time <= @assigned_orig.end_time)
        @new.volunteer_shift_id = @assigned_orig.volunteer_shift_id
        @new.contact_id = cid
      end

      success = 0
      if @assigned && @assigned.valid?
        begin
          @assigned.save!
          success += 1
        rescue => e
          errors = [e]
          flash[:jsalert] = "Cannot reassign shifts: #{errors.join(", ")}"
          raise ActiveRecord::Rollback
        end
      end

      if success == 1 && @new.valid?
        begin
          @new.save!
          success += 1
        rescue => e
          errors = [e]
          flash[:jsalert] = "Cannot reassign shifts: #{errors.join(", ")}"
          raise ActiveRecord::Rollback
        end
      end

      if @assigned && success != 2
        errors = (success == 0) ? @assigned.errors.full_messages : @new.errors.full_messages
        flash[:jsalert] = "Cannot reassign shifts: #{errors.join(", ")}"
      end
      if success != 2
        raise ActiveRecord::Rollback
      end
    end
    end
    end

    redirect_skedj(request.env["HTTP_REFERER"], @assigned_orig ? @assigned_orig.volunteer_shift.date_anchor : "")
  end

  def attendance
    render :update do |page|
      begin
        @assignment = Assignment.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        page.alert("The assignment (##{params[:id]}) seems to have disappeared. It is possible somebody else has modified or deleted it.")
      end
      page.hide loading_indicator_id("skedjul_#{params[:skedjul_loading_indicator_id]}_loading")
      if @assignment
        page << "show_message(#{(render :partial => "attendanceform").to_json});"
      end
    end
  end

  def doattendance
    success = false
    begin
      @assignment = Assignment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
    end
    if @assignment
      @assignment.attendance_type_id = params[:attendance][:attendance_type_id] if params[:attendance]
      begin
        success = @assignment.save
      rescue ActiveRecord::StaleObjectError
      end
    end
    if success and params[:cancel]
      at = AttendanceType.find_by_name("cancelled")
      params[:cancel].each do |i|
        assignment = Assignment.find_by_id(i)
        if assignment
          assignment.attendance_type = at
          assignment.save
        end
      end
    end
    if success and params[:close_shift] and params[:close_shift] == "1"
      a = Assignment.new
      a.volunteer_shift_id = @assignment.volunteer_shift_id
      a.start_time = @assignment.start_time
      a.end_time = @assignment.end_time
      a.closed = true
      a.save
    end
    render :update do |page|
      if success
        page.reload
#        page << "selection_toggle(#{params[:id]});"
#        page << "popup1.hide();"
      else
        page.alert("The assignment (##{params[:id]}) seems to have disappeared. It is possible somebody else has modified or deleted it.")
      end
      page.hide loading_indicator_id("attendance_assignment_form")
    end
  end

  def split
    @assignment = Assignment.find(params[:id])
    render :update do |page|
      page.hide loading_indicator_id("skedjul_#{params[:skedjul_loading_indicator_id]}_loading")
      page << "show_message(#{(render :partial => "splitform").to_json});"
    end
  end

  def dosplit
    sp = params[:split].to_a.sort_by{|k,v| k}.map{|a| a[1].to_i}
    @assignment = Assignment.find(params[:id])
    old_end = @assignment.end_time
    @assignment.end_time = @assignment.send(:instantiate_time_object, "split_time", sp)
    new_end = @assignment.end_time
    success = ((@assignment.end_time < old_end) and (@assignment.end_time > @assignment.start_time))
   if success
      success = @assignment.save
      if success
        @assignment = Assignment.new(@assignment.attributes)
        @assignment.start_time = new_end
        @assignment.end_time = old_end
        success = @assignment.save
      end
    end
    render :update do |page|
      if success
        page.reload
#        page << "selection_toggle(#{params[:id]});"
#        page << "popup1.hide();"
      else
        page << "alert('split failed. this is probably due to the time not being within the correct range.');"
      end
      page.hide loading_indicator_id("split_assignment_form")
    end
  end

  def arrived
    begin
      a = Assignment.find(params[:id])
      a.attendance_type = AttendanceType.find_by_name("arrived")
      if !a.valid?
        flash[:jsalert] = a.errors.full_messages.join(", ")
      else
        begin
          a.save! # if !a.save ? flash[:error] = "Failed to save record as arrived for unknown reason"
        rescue ActiveRecord::StaleObjectError
        end
        if a.contact and not a.contact.is_old_enough?
          flash[:jsalert] = "This volunteer is not yet #{Default['minimum_volunteer_age']} years old (based on their saved birthday: #{a.contact.birthday.to_s}).\nPlease remind the volunteer that they must have an adult with them to volunteer."
        end
        nc_ns = a.nc_ns_since_last_arrived
        if nc_ns.length > 0
          msg = "This volunteer had No Call/No Show instance(s) on #{nc_ns.map{|x| x.date}.uniq.to_sentence}.\nPlease remind them that they must call in if they are not able to come in."
          flash[:jsalert] = flash[:jsalert] ? (flash[:jsalert] + "\n\n" + msg) : msg
        end
      end
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "Assignment was deleted before it could be marked as arrived"
    end
    redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_shift.date_anchor : "")
  end

  def search
    @conditions = Conditions.new
    params[:conditions] ||= {}
    @conditions.apply_conditions(params[:conditions])
    @results = Assignment.paginate(:page => params[:page], :conditions => @conditions.conditions(Assignment), :order => "volunteer_events.date ASC", :per_page => 50, :include => [:volunteer_shift => [:volunteer_event]])
  end

  def copy
    @assignment = Assignment.find(params[:id])
    @my_url = {:action => "create_shift", :controller => "volunteer_events"}
    @assignment.id = nil
    @action_title = "Copying"
    edit
  end

  def edit
    if @assignment
      @assignments = [@assignment]
    else
      begin
        @assignments = params[:id].split(",").map{|x| Assignment.find(x)}
        @assignment = @assignments.first
      rescue
        flash[:error] = $!.to_s
        redirect_skedj(request.env["HTTP_REFERER"], "")
        return
      end
    end
    @referer = request.env["HTTP_REFERER"]
    @my_url ||= {:action => "update", :id => params[:id]}
    render :action => 'edit'
  end

  def update
    unless params[:assignment]
      redirect_to :action => "index"
      return
    end
    @my_url = {:action => "update", :id => params[:id]}
    last_id = nil
    begin
      @assignments = params[:id].split(",").map{|x| last_id = x; Assignment.find(x)}
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "The assignment (##{last_id.to_i.inspect}) seems to have disappeared or never existed. It is possible somebody else has modified or deleted it."
      rt = params[:assignment].delete(:redirect_to)
      redirect_skedj(rt, "")
      return
    end
    lv = params["lock_versions"]
    ac = params["assigned_contacts"] || {}
    @assigned_contacts = []
    @replaced_contacts = []
    ret = true
    @assignments.each do |as|
      as.lock_version = lv[as.id.to_s]
      if as.lock_version_changed?
        as.errors.add("lock_version", "is stale for this assignment, which means it has been edited by somebody else since you opened it, please try again")
        ret = false
      end
      if as.contact_id && as.contact_id.to_s != params[:assignment][:contact_id].to_s
        @assigned_contacts << as.contact
        unless ac[as.contact_id.to_s] && ac[as.contact_id.to_s] == "replace"
          as.errors.add("contact_id", "has been changed, please confirm below that the volunteer who is already assigned to the shift should be removed")
          ret = false
        else
          @replaced_contacts << as.contact_id
        end
      end
    end
    rt = params[:assignment].delete(:redirect_to)

    js_alert = nil

    if ! ret
      @assignment = Assignment.new
      @assignment.volunteer_shift = @assignments.first.volunteer_shift
      @assignment.attributes=(params[:assignment]) # .. ? .delete("volunteer_shift_attributes")
    end

    @assignments.each{|x|
      if ret
        @assignment = x
        bc = x.contact_id
        ret = !!(x.update_attributes(params[:assignment]))
        if bc != x.contact_id and x.first_time_in_area?
          alert = "#{x.contact.display_name} (##{x.contact_id}) has never logged hours for the #{x.volunteer_shift.volunteer_task_type.description} task type. Please remind the volunteer of the requirements for this area."
          if x.volunteer_shift.volunteer_event and x.volunteer_shift.volunteer_event.notes and x.volunteer_shift.volunteer_event.notes.length > 0
            alert += "\n\nSome suggested notes saved in the database for this event are:\n" + x.volunteer_shift.volunteer_event.notes
          end
          js_alert = alert
        end
      end
    }

    if ret && @assignment.contact and not @assignment.contact.is_old_enough?
      msg = "This volunteer is not yet #{Default['minimum_volunteer_age']} years old (based on their saved birthday: #{@assignment.contact.birthday.to_s}).\nPlease remind the volunteer that they must have an adult with them to volunteer."
      if js_alert == nil
        js_alert = msg
      else
        js_alert = msg + "\n\n" + js_alert
      end
    end

    flash[:jsalert] = js_alert if js_alert

    if ret
      flash[:notice] = 'Assignment was successfully updated.'
      redirect_skedj(rt, @assignment.volunteer_shift.date_anchor)
    else
      @referer = rt
      render :action => "edit"
    end
  end
end
