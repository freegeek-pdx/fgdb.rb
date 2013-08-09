class DefaultAssignmentsController < ApplicationController
  protected

  public

  layout :with_sidebar

  helper :skedjul

  def open
    begin
      a = DefaultAssignment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "Assignment was deleted before it could be marked as open"
    end
    a.closed = false if a
    if a && a.valid?
      a.save!
    else
      flash[:jsalert] = "An unknown error prevented the shift from being marked open" if flash[:jsalert].nil?
    end
    redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_default_shift.volunteer_default_event.weekday.name : "")
  end

  def close
    begin
      a = DefaultAssignment.find(params[:id])
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
    redirect_skedj(request.env["HTTP_REFERER"], a ? a.volunteer_default_shift.volunteer_default_event.weekday.name : "")
  end

  def index
    @multi_enabled = true
    if params[:conditions]
      my_sort_prepend = params[:conditions][:sked_enabled] == "true" ? "(SELECT position FROM rosters_skeds WHERE sked_id = #{params[:conditions][:sked_id]} AND roster_id = volunteer_default_shifts.roster_id), " : "volunteer_default_shifts.roster_id, "
    @skedj = Skedjul.new({
      :conditions => ['contact', "sked", "roster", "volunteer_task_type", "assigned", "weekday"],

      :generate_param_key => "date_range",
      :generate_conditions => ["sked", "roster"],

      :block_method_name => "volunteer_default_shifts.volunteer_default_events.weekday_id",
      :block_method_display => "volunteer_default_shifts.volunteer_default_events.weekdays.name",
      :block_start_time => "volunteer_default_shifts.volunteer_default_events.weekdays.start_time",
      :block_end_time => "volunteer_default_shifts.volunteer_default_events.weekdays.end_time",
#      :default_view => "by_slot",
                           :table_head_partial => "default_assignments/multi_edit",
                           :cell_onclick => "selection_toggle",

                            :left_unique_value => "default_assignments.left_method_name",
                               :left_method_name => "default_assignments.left_method_name",
                           :left_sort_value => "#{my_sort_prepend}(coalesce(volunteer_task_types.description, volunteer_default_events.description)), volunteer_default_shifts.description, default_assignments.slot_number",
                               :left_table_name => "volunteer_default_shifts",
                               :left_link_action => "assign",
                               :title_between => 'volunteer_default_shifts.rosters.name',
#                               :break_between_difference => "default_assignments.slot_type_desc",

                               :thing_start_time => "default_assignments.start_time",
                               :thing_end_time => "default_assignments.end_time",
                               :thing_table_name => "default_assignments",
                               :thing_description => "time_range_s,display_name",
                               :thing_link_id => "default_assignments.id",
                               :thing_links => [[:reassign, :function, :contact_id], [:split, :remote, :contact_id],[:edit, :link], [:copy, :link, :volshift_stuck],  [:close, :link, :not_assigned, :x], [:open, :link, :closed], [:destroy, :confirm, :contact_id]],


      }, params)

    @opts = @skedj.opts
    @conditions = @skedj.conditions
      @conditions.effective_on_enabled = "true"
      @conditions.effective_on_start = (Date.today - 14).to_s
      @conditions.effective_on_end = (Date.today + 60).to_s

    @skedj.find({:conditions => @skedj.where_clause, :include => [:contact => [], :volunteer_default_shift => [:volunteer_task_type, :volunteer_default_event]]})
    render :partial => "work_shifts/skedjul", :locals => {:skedj => @skedj }, :layout => :with_sidebar
    else
      render :partial => "index",  :layout => :with_sidebar
    end
  end

  def reassign
    assigned, available = params[:id].split(",")

    Assignment.transaction do
    # readonly
    begin
      @assigned_orig = DefaultAssignment.find(assigned)
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "The assignment (##{assigned}) seems to have disappeared. It is possible somebody else has modified or deleted it."
    end

    begin
      @available = DefaultAssignment.find(available)
    rescue ActiveRecord::RecordNotFound
      flash[:jsalert] = "The assignment (##{available}) seems to have disappeared. It is possible somebody else has modified or deleted it."
    end

    if @assigned_orig && @available
    if @available.volunteer_default_shift.stuck_to_assignment or @assigned_orig.volunteer_default_shift.stuck_to_assignment
      flash[:jsalert] = "Cannot reassign an intern shift, please either delete the intern shift or assign it to somebody else"
    else
      cid = @available.contact_id
      if cid
        @available.contact_id = nil
        @available.save
      end

      # for write
      begin
        @assigned = DefaultAssignment.find(assigned)
      rescue ActiveRecord::RecordNotFound
        flash[:jsalert] = "The assignment (##{assigned}) seems to have disappeared. It is possible somebody else has modified or deleted it."
      end

      if @assigned
        @new = DefaultAssignment.new # available

        # do it
        @assigned.volunteer_default_shift_id = @available.volunteer_default_shift_id
        @assigned.slot_number = @available.slot_number
        @assigned.start_time = @available.start_time if (@assigned.start_time < @available.start_time) or (@assigned.start_time >= @available.end_time)
        @assigned.end_time = @available.end_time if (@assigned.end_time > @available.end_time) or (@assigned.end_time <= @available.start_time)

        @new.start_time = @available.start_time
        @new.start_time = @assigned_orig.start_time if (@new.start_time < @assigned_orig.start_time) or (@new.start_time >= @assigned_orig.start_time)
        @new.end_time = @available.start_time
        @new.end_time = @assigned_orig.end_time if (@new.end_time > @assigned_orig.end_time) or (@new.end_time <= @assigned_orig.end_time)
        @new.volunteer_default_shift_id = @assigned_orig.volunteer_default_shift_id
        @new.slot_number = @assigned_orig.slot_number
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

    redirect_skedj(request.env["HTTP_REFERER"], @assigned_orig ? @assigned_orig.volunteer_default_shift.volunteer_default_event.weekday.name : "")
  end

  def split
    @assignment = DefaultAssignment.find(params[:id])
    render :update do |page|
      page.hide loading_indicator_id("skedjul_#{params[:skedjul_loading_indicator_id]}_loading")
      page << "show_message(#{(render :partial => "splitform").to_json});"
    end
  end

  def dosplit
    sp = params[:split].to_a.sort_by{|k,v| k}.map{|a| a[1].to_i}
    @assignment = DefaultAssignment.find(params[:id])
    old_end = @assignment.end_time
    @assignment.end_time = @assignment.send(:instantiate_time_object, "split_time", sp)
    new_end = @assignment.end_time
    success = ((@assignment.end_time < old_end) and (@assignment.end_time > @assignment.start_time))
   if success
      success = @assignment.save
      if success
        @assignment = DefaultAssignment.new(@assignment.attributes)
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

  def search
    @conditions = Conditions.new
    params[:conditions] ||= {}
    @conditions.apply_conditions(params[:conditions])
    @results = Assignment.paginate(:page => params[:page], :conditions => @conditions.conditions(Assignment), :order => "created_at ASC", :per_page => 50)
  end

  def copy
    @assignment = DefaultAssignment.find(params[:id])
    @my_url = {:action => "create_shift", :controller => "volunteer_default_events"}
    @assignment.id = nil
    @action_title = "Copying"
    edit
  end

  def edit
    if @assignment
      @assignments = [@assignment]
    else
      begin
        @assignments = params[:id].split(",").map{|x| DefaultAssignment.find(x)}
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
    @my_url = {:action => "update", :id => params[:id]}
    @assignments = params[:id].split(",").map{|x| DefaultAssignment.find(x)}

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
      if as.contact_id && as.contact_id.to_s != params[:default_assignment][:contact_id].to_s
        @assigned_contacts << as.contact
        unless ac[as.contact_id.to_s] && ac[as.contact_id.to_s] == "replace"
          as.errors.add("contact_id", "has been changed, please confirm below that the volunteer who is already assigned to the shift should be removed")
          ret = false
        else
          @replaced_contacts << as.contact_id
        end
      end
    end
    rt = params[:default_assignment].delete(:redirect_to)

    if ! ret
      @assignment = DefaultAssignment.new(params[:default_assignment])
      @assignment.volunteer_default_shift = @assignments.first.volunteer_default_shift
    end

    @assignments.each{|x|
      if ret
        @assignment = x
        ret = !!(x.update_attributes(params[:default_assignment]))
      end
    }

    if ret
      flash[:notice] = 'DefaultAssignment was successfully updated.'
      redirect_skedj(rt, @assignment.volunteer_default_shift.volunteer_default_event.weekday.name)
    else
      @referer = rt
      render :action => "edit"
    end
  end

  def destroy
    @assignment = DefaultAssignment.find(params[:id])
    @assignment.destroy

    redirect_skedj(request.env["HTTP_REFERER"], @assignment.volunteer_default_shift.volunteer_default_event.weekday.name)
  end
end
