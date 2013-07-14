class VolunteerEventsController < ApplicationController
  protected
  def get_required_privileges
    a = super
    a << {:privileges => ['admin_skedjul'], :except => ['display']}
    a << {:privileges => ['schedule_volunteers'], :only => ['display']}
    a
  end
  public
  layout :with_sidebar

  def toggle_walkins
    v = VolunteerEvent.find_by_id(params[:id])
    v.nowalkins = !v.nowalkins
    v.save!
    if v.nowalkins
      v.volunteer_shifts.each do |vs|
        vs.fill_in_available
      end
    end
    redirect_to :back
  end

  def index
    redirect_to :controller => "assignments"
    # @volunteer_events = VolunteerEvent.find(:all)
  end

  def add_shift
    ve = nil
    if !params["id"].blank?
      ve = VolunteerEvent.find_by_id(params["id"])
    else
      ve = VolunteerEvent.new
    end
    vs = ve.volunteer_shifts.new
    vs.program = Program.find_by_name("intern")
#    vs.slot_count = 1
    vs.volunteer_event_id = ve.id if ve.id
    vs.volunteer_event = ve
    a = vs.assignments.new
    a.volunteer_shift = vs
    vs.stuck_to_assignment = vs.not_numbered = true
    @assignments = vs.assignments = [a]
    @referer = request.env["HTTP_REFERER"]
    @my_url = {:action => "create_shift", :id => params[:id]}
    @assignment = a
    render :template => 'assignments/edit'
  end

  # ve = VolunteerEvent.find(params["id"])
  # vs = ve.volunteer_shifts.new(params["assignment"]["volunteer_shift_attributes"])
  # vs.not_numbered = vs.stuck_to_assignment = true
  # a = vs.assignments.new(params["assignment"])
  # a.volunteer_shift = vs
  # a.set_values_if_stuck
  # vs.save
  # vs = VolunteerShift.find(vs.id)
  # a = vs.assignments.first
  # a.attributes=(params["assignment"])
  # a.volunteer_shift = vs # FIXME: would a hidden id field help?
  # a.save

  def create_shift
    ve = nil
    if !params["id"].blank?
      ve = VolunteerEvent.find(params["id"])
    else
      if (params["assignment"]["volunteer_shift_attributes"]["roster_id"].blank? || params["assignment"]["set_date"].blank?)
        ve = VolunteerEvent.new # won't save
      else
        ve = Roster.find_by_id(params["assignment"]["volunteer_shift_attributes"]["roster_id"]).vol_event_for_date(params["assignment"]["set_date"])
      end
    end
    vs = ve.volunteer_shifts.new
#    vs.slot_count = 1
#    vs.volunteer_event_id = ve.id
#    vs.volunteer_event = ve
    vs.stuck_to_assignment = vs.not_numbered = true
    vs.attributes=(params["assignment"]["volunteer_shift_attributes"])
    a = vs.assignments.new
    a.volunteer_shift = vs
#    a.volunteer_shift_id = vs.id
    a.attributes = (params["assignment"])
    @assignments = vs.assignments = [a]
    vs.set_values_if_stuck
    vs.assignments = []
    @success = a.valid? && vs.save
    rt = params[:assignment].delete(:redirect_to)
    @my_url = {:action => "create_shift", :id => params[:id]}
    @assignment = a
    if @success
      vs = vs.reload
      @assignment = a = vs.assignments.new
      a.volunteer_shift = vs
      #    a.volunteer_shift_id = vs.id
      a.attributes = (params["assignment"])
      @assignments = vs.assignments = [a]

      if !@success
        vs.destroy
      end
    end
    if @success # and @assignment.volunteer_shift.save
      redirect_skedj(rt, ve.date_anchor)
    else
      render :template => 'assignments/edit'
    end
  end

  def show
    @volunteer_event = VolunteerEvent.find(params[:id])
  end

  def display
    @volunteer_event = VolunteerEvent.find(params[:id])
  end

  def new_class
    @notice = ""
    c = params[:klass]
    if c.nil?
      render :action => "new_class"
      return
    end
    c[:contact_id] = params["contact"]["id"] if params["contact"] and params["contact"]["id"]
    c[:contact2_id] = params["contact"]["contact2_id"] if params["contact"] and params["contact"]["contact2_id"]
    normal = c[:student_slot_count].to_i || 0
    instructor = c[:instructor_slot_count].to_i || 0
    audit = c[:audit_slot_count].to_i || 0
    roster = Roster.find_by_id(c[:roster_id].to_i)
    program = Program.find_by_id(c[:program_id].to_i)
    resource = Resource.find_by_id(c[:resource_id].to_i)
    contact = Contact.find_by_id(c[:contact_id].to_i)
    contact2 = Contact.find_by_id(c[:contact2_id].to_i)
#    if roster.nil? or program.nil?
#      redirect_to :action => "new_class"
#      return
#    end
    start_hour = c["start_time(4i)"].to_i
    start_minute = c["start_time(5i)"].to_i
    if c["start_time(7i)"].to_i == ActionView::Helpers::DateTimeSelector::PM
      start_hour += 12 unless start_hour == 12
    else
      start_hour -= 12 if start_hour == 12
    end
    start_time = Time.parse("2000-01-01 " + [start_hour, start_minute].join(":"))
    end_hour = c["end_time(4i)"].to_i
    end_minute = c["end_time(5i)"].to_i
    if c["end_time(7i)"].to_i == ActionView::Helpers::DateTimeSelector::PM
      end_hour += 12 unless end_hour == 12
    else
      end_hour -= 12 if end_hour == 12
    end
    end_time = Time.parse("2000-01-01 " + [end_hour, end_minute].join(":"))
    c["start_time"] = start_time
    c["end_time"] = end_time
    c["program"] = program
    c["roster"] = roster
    c["resource"] = resource
    params["contact"] ||= {}
    params["contact"]["id"] = contact.id if contact
    params["contact"]["contact2_id"] = contact2.id if contact2
    @volunteer_event = VolunteerEvent.new
    @volunteer_event.description = c[:description]
    @volunteer_event.date = c[:date]
    @volunteer_event.notes = c[:notes]
    inst_shift = nil
    inst_shift2 = nil
    normal.times do |i|
      a = VolunteerShift.new
      a.class_credit = true
      a.roster_id = roster.id if roster
      a.program_id = program.id if program
      a.slot_number = (i + 1) # starts 0
      a.start_time = start_time
      a.end_time = end_time
      @volunteer_event.volunteer_shifts << a
    end
    audit.times do |i|
      a = VolunteerShift.new
      a.class_credit = false
      a.description = "AUDIT"
      a.roster_id = roster.id if roster
      a.program_id = program.id if program
      a.slot_number = (normal + i + 1) # starts 0
      a.start_time = start_time
      a.end_time = end_time
      @volunteer_event.volunteer_shifts << a
    end
    vtt_t = VolunteerTaskType.find_by_name("teaching")
    instructor.times do |i|
      a = VolunteerShift.new
      a.class_credit = false
      a.volunteer_task_type = vtt_t
      a.roster_id = roster.id if roster
      a.program_id = program.id if program
      a.start_time = start_time
      a.end_time = end_time
      a.not_numbered = true
      a.description = @volunteer_event.description
      a.volunteer_event = @volunteer_event
      if contact and i == 0
        inst_shift = a
      end
      if contact2 and i == 1
        inst_shift2 = a
      end
      @volunteer_event.volunteer_shifts << a
    end
    if resource
      a = ResourcesVolunteerEvent.new
      a.resource = resource
      a.roster_id = roster.id if roster
      a.start_time = start_time
      a.end_time = end_time
      @volunteer_event.resources_volunteer_events << a
    end
    if @volunteer_event.save
      if inst_shift
        a = inst_shift.assignments.first
        a.contact_id = contact.id
        a.save
      end
      if inst_shift2
        a = inst_shift2.assignments.first
        a.contact_id = contact2.id
        a.save
      end
      @notice_id = @volunteer_event.id
      @volunteer_event = VolunteerEvent.new
      @notice = "\"#{c[:description]}\" created successfully"
      render :action => "new_class"
    else
      def c.method_missing(sym)
        self[sym]
      end
      @klass = c
      render :action => "new_class"
    end
  end

  def new
    @volunteer_event = VolunteerEvent.new
  end

  def copy
    old = VolunteerEvent.find_by_id(params[:id])
    copy_for = []
    old.volunteer_shifts.map{|x| x.volunteer_task_type}.uniq.each do |vtt|
      if params["copy_for_#{vtt ? vtt.id.to_s : "nil"}"] == "1"
        copy_for << (vtt ? vtt.id : nil)
      end
    end
    new = old.copy_to(Date.parse(params[:copy][:date]), hours_val(params[:copy]), copy_for)
    if new.class == VolunteerEvent
      redirect_to :action => "show", :id => new.id
    else
      flash[:error] = "The following volunteers are already scheduled during that time: #{new.map{|x| x.contact.display_name}.join(", ")}"
      redirect_to :back
    end
  end

  def edit
    @volunteer_event = VolunteerEvent.find(params[:id])
    @referer = request.env["HTTP_REFERER"]
  end

  def create
    @volunteer_event = VolunteerEvent.new(params[:volunteer_event])

    _save
    if @volunteer_shifts.select{|x| !x.valid?}.length == 0 && @resources.select{|x| !x.valid?}.length == 0 && @volunteer_event.valid? && @volunteer_event.save
      _after_save
      flash[:notice] = 'VolunteerEvent was successfully created.'
      redirect_to({:action => "show", :id => @volunteer_event.id})
    else
      render :action => "new"
    end
  end

  def update
    @volunteer_event = VolunteerEvent.find(params[:id])
    rt = params[:volunteer_event].delete(:redirect_to)

    _save
    if @volunteer_shifts.select{|x| !x.valid?}.length == 0 && @resources.select{|x| !x.valid?}.length == 0 && @volunteer_event.valid? && @volunteer_event.update_attributes(params[:volunteer_event])
      _after_save
      flash[:notice] = 'VolunteerEvent was successfully updated.'
      redirect_skedj(rt, @volunteer_event.date_anchor)
    else
      render :action => "edit"
    end
  end

  def _save
    @volunteer_shifts = apply_line_item_data(@volunteer_event, VolunteerShift)
    @resources = apply_line_item_data(@volunteer_event, ResourcesVolunteerEvent)
  end

  def _after_save
    @volunteer_shifts.each{|x| x.save!}
    @resources.each{|x| x.save!}
  end

  def destroy
    @volunteer_event = VolunteerEvent.find(params[:id])
    @volunteer_event.destroy

    redirect_to({:action => "index"})
  end
end
