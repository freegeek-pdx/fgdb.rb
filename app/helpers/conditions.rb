class Conditions < ConditionsBase
  attr_accessor :data_type # hax

  DATES = %w[
      created_at recycled_at disbursed_at received_at
      worked_at bought_at date_performed donated_at occurred_at
      shift_date date updated_at last_build last_volunteer_date
      last_donated_date last_donated_gizmos_only_date
      last_donated_contribution_only_date
  ]

  CONDS = (%w[
      id contact_type needs_attention anonymous unresolved_invoices
      payment_method payment_amount gizmo_type_id gizmo_category_id covered
      postal_code city phone_number contact volunteer_hours email
      flagged system contract created_by cashier_created_by extract
      empty disbursement_type_id store_credit_id organization shift_type
      can_login role action worker contribution serial_number job
      volunteer_task_type weekday sked roster effective_at cancelled
      needs_checkin assigned attendance_type worker_type gizmo_type_group_id
      effective_on schedule type store_credit_redeemed volunteered_hours_in_days
      updated_by cashier_updated_by is_pickup finalized gizmo_context_id
      logged_in_within signed_off_by payment_total organization_name
      model vendor result interface_type megabytes_size week unresolved_shipment
      volunteered_non_court_hours_in_days form_factor hard_drive_serial_number
      sale_type processor_product program_id generated_shift
    ] + DATES).uniq

  CHECKBOXES = %w[ cancelled ]

  for i in CONDS
    attr_accessor (i + "_enabled").to_sym
    attr_accessor (i + "_excluded").to_sym
  end

  for i in DATES
    attr_accessor (i + '_date').to_sym, (i + '_date_type').to_sym, (i + '_start_date').to_sym, (i + '_end_date').to_sym, (i + '_month').to_sym, (i + '_year').to_sym, (i + '_year_only').to_sym, (i + '_year_q').to_sym, (i + '_quarter').to_sym
  end

  attr_accessor :hard_drive_serial_number

  attr_accessor :processor_product

  attr_accessor :shift_type

  attr_accessor :form_factor

  attr_accessor :week

  attr_accessor :model, :vendor, :interface_type, :result

  attr_accessor :gizmo_context_id

  attr_accessor :organization_name

  attr_accessor :signed_off_by

  attr_accessor :volunteer_hours_days, :volunteer_hours_minimum
  attr_accessor :volunteer_non_court_hours_days, :volunteer_non_court_hours_minimum

  attr_accessor :logged_in_within

  attr_accessor :cancelled

  attr_accessor :volunteer_task_type_id

  attr_accessor :weekday_id
  attr_accessor :roster_id
  attr_accessor :sked_id

  attr_accessor :schedule_id

  attr_accessor :effective_at

  attr_accessor :effective_on_start, :effective_on_end

  attr_accessor :worker_id

  attr_accessor :job_id

  attr_accessor :created_by, :cashier_created_by
  attr_accessor :updated_by, :cashier_updated_by

  attr_accessor :serial_number

  attr_accessor :contact_id

  attr_accessor :contract_id

  attr_accessor :payment_method_id

  attr_accessor :id

  attr_accessor :system_id

  attr_accessor :needs_attention

  attr_accessor :anonymous

  attr_accessor :unresolved_invoices

  attr_accessor :unresolved_shipment

  attr_accessor :gizmo_type_id

  attr_accessor :program_id

  attr_accessor :gizmo_type_group_id

  attr_accessor :gizmo_category_id

  attr_accessor :megabytes_size_type, :megabytes_size_exact, :megabytes_size_low, :megabytes_size_high, :megabytes_size_ge, :megabytes_size_le, :megabytes_size_units
  attr_accessor :payment_amount_type, :payment_amount_exact, :payment_amount_low, :payment_amount_high, :payment_amount_ge, :payment_amount_le
  attr_accessor :payment_total_type, :payment_total_exact, :payment_total_low, :payment_total_high, :payment_total_ge, :payment_total_le

  attr_accessor :contact_type

  attr_accessor :city, :postal_code, :phone_number, :email

  attr_accessor :volunteer_hours_type, :volunteer_hours_exact, :volunteer_hours_low, :volunteer_hours_high, :volunteer_hours_ge, :volunteer_hours_le

  attr_accessor :extract_type, :extract_value, :extract_field

  attr_accessor :disbursement_type_id

  attr_accessor :store_credit_id

  attr_accessor :attendance_type_id

  attr_accessor :worker_type_id

  attr_accessor :sale_type_id

  attr_accessor :role

  attr_accessor :action
  attr_accessor :type_id

  def init_callback
    @payment_method_id = PaymentMethod.cash.id
    DATES.each do |x|
      self.send(x + "_date=", Date.today.to_s)
    end
  end

  def validate
    if ! @condition_applied
      return
    end
    if CONDS.select{|x| is_this_condition_enabled(x)}.length == 0
      @errors.add_to_base('Conditions have not been chosen')
      return
    end
    @errors.add("phone_number", "is not ten digits long") if validate_emptyness('phone_number') && @phone_number.to_s.gsub(/[^[:digit:]]/, "").length != 10
    validate_exists('worker_id') if parse_and_validate_list('worker', 'worker_id', true)
    validate_exists('job_id') if parse_and_validate_list('job', 'job_id')
    validate_exists('weekday_id') if parse_and_validate_list('weekday', 'weekday_id')
    validate_exists('roster_id') if parse_and_validate_list('roster', 'roster_id')     # TODO: this _id needs to be consistent, really..
    validate_exists('gizmo_type_id') if parse_and_validate_list('gizmo_type_id')
    validate_exists('program_id') if parse_and_validate_list('program_id')
    validate_exists('gizmo_type_group_id') if parse_and_validate_list('gizmo_type_group_id')
    # @errors.add("foo", "is bad") #if is_this_condition_enabled('foo') && @foo == 'bad'
    validate_integer('id')
    validate_emptyness('email')
    validate_emptyness('city')
    validate_emptyness('postal_code')
    validate_exists('contact_id') if validate_integer('contact', 'contact_id')
    validate_exists('sked_id') if validate_integer('sked', 'sked_id')
    validate_exists('role') if validate_integer('role', 'role')
    validate_exists('action') if validate_integer('action')
    validate_exists('type_id') if validate_integer('type', 'type_id')
    validate_exists('contact_type') if validate_integer('contact_type')
    validate_exists('gizmo_category_id') if validate_integer('gizmo_category_id')
    validate_exists('system_id') if validate_integer('system', 'system_id')
    validate_exists('contract_id') if validate_integer('contract', 'contract_id')
    validate_exists('disbursement_type_id') if parse_and_validate_list('disbursement_type_id')
    validate_exists('contract_id') if validate_integer('contract', 'contract_id')
    validate_exists('payment_method_id') if validate_integer('payment_method', 'payment_method_id')
    validate_exists('attendance_type_id') if validate_integer('attendance_type', 'attendance_type_id')
    validate_exists('worker_type_id') if validate_integer('worker_type', 'worker_type_id')
    validate_exists('sale_type_id') if validate_integer('sale_type', 'sale_type_id')
    validate_exists('volunteer_task_type_id') if parse_and_validate_list('volunteer_task_type', 'volunteer_task_type_id')
    validate_exists('schedule_id') if validate_integer('schedule', 'schedule_id')
    validate_emptyness('store_credit_id')
    if is_this_condition_enabled('payment_amount')
      case @payment_amount_type
      when '>='
        validate_integer('payment_amount', 'payment_amount_ge', false, true)
      when '<='
        validate_integer('payment_amount', 'payment_amount_le', false, true)
      when 'exact'
        validate_integer('payment_amount', 'payment_amount_exact', false, true)
      when 'between'
        validate_integer('payment_amount', 'payment_amount_low', false, true)
        validate_integer('payment_amount', 'payment_amount_high', false, true)
      else
        errors.add('payment_amount_type', 'is not a valid search type')
      end
    end
    if is_this_condition_enabled('megabytes_size')
      case @megabytes_size_type
      when '>='
        validate_integer('megabytes_size', 'megabytes_size_ge', true, true)
      when '<='
        validate_integer('megabytes_size', 'megabytes_size_le', false, true)
      when 'exact'
        validate_integer('megabytes_size', 'megabytes_size_exact', false, true)
      when 'between'
        validate_integer('megabytes_size', 'megabytes_size_low', false, true)
        validate_integer('megabytes_size', 'megabytes_size_high', true, true)
      else
        errors.add('megabytes_size_type', 'is not a valid search type')
      end
    end
    if is_this_condition_enabled('payment_total')
      case @payment_total_type
      when '>='
        validate_integer('payment_total', 'payment_total_ge', true, true)
      when '<='
        validate_integer('payment_total', 'payment_total_le', true, true)
      when 'exact'
        validate_integer('payment_total', 'payment_total_exact', true, true)
      when 'between'
        validate_integer('payment_total', 'payment_total_low', true, true)
        validate_integer('payment_total', 'payment_total_high', true, true)
      else
        errors.add('payment_total_type', 'is not a valid search type')
      end
    end
    validate_exists('created_by', 'users') if validate_integer('created_by')
    validate_exists('cashier_created_by', 'users') if validate_integer('cashier_created_by')
    validate_exists('updated_by', 'users') if validate_integer('updated_by')
    validate_exists('cashier_updated_by', 'users') if validate_integer('cashier_updated_by')
    validate_exists('signed_off_by', 'users') if validate_integer('signed_off_by')
    validate_integer('volunteered_hours_in_days', 'volunteer_hours_days')
    validate_integer('volunteered_hours_in_days', 'volunteer_hours_minimum', true, true)
    validate_integer('volunteered_non_court_hours_in_days', 'volunteer_non_court_hours_days')
    validate_integer('volunteered_non_court_hours_in_days', 'volunteer_non_court_hours_minimum', true, true)
    if is_this_condition_enabled('volunteer_hours')
      case @volunteer_hours_type
      when '>='
        validate_integer('volunteer_hours', 'volunteer_hours_ge', false, true)
      when '<='
        validate_integer('volunteer_hours', 'volunteer_hours_le', false, true)
      when 'exact'
        validate_integer('volunteer_hours', 'volunteer_hours_exact', false, true)
      when 'between'
        validate_integer('volunteer_hours', 'volunteer_hours_low', false, true)
        validate_integer('volunteer_hours', 'volunteer_hours_high', false, true)
      else
        errors.add('volunteer_hours_type', 'is not a valid search type')
      end
    end
    validate_date('effective_at')
    validate_date('effective_on', 'effective_on_start', 'effective_on_end')
    DATES.each do |x|
      validate_date_chooser(x)
    end
  end

  def validate_date_chooser(name)
    return unless is_this_condition_enabled(name)
    case self.send(name + "_date_type")
      when 'arbitrary'
      validate_date(name, name + "_start_date", name + "_end_date")
      when 'daily'
      validate_date(name, name + "_date")
    end
  end

  def validate_integer(name, varname = nil, allowzero = false, not_i = false)
    varname ||= name
    if is_this_condition_enabled(name)
      value = self.send(varname)
      return false if _empty_check(varname, value) # do not include other errors, if blank
      result = true
      unless allowzero
        if value.to_f == 0.0
          errors.add(varname, 'cannot be zero')
          result = false
        end
      end
      unless not_i
        if value.to_i.to_s != value.to_s.strip
          errors.add(varname, 'is not a whole number')
          result = false
        end
          if value.to_i > 2147483647 || value.to_i < -2147483648
            errors.add(varname, 'is not in the valid range of integer numbers')
            result = false
          end
      end
      return result
    end
    false
  end

  def validate_date(name, varname = nil, second = nil)
    varname ||= name
    if is_this_condition_enabled(name)
      begin
        val = self.send(varname)
        start = val.class == Date ? val : Date.parse(val)
      rescue
        errors.add(varname, 'is not a valid date')
      end
      if second
        begin
          val2 = self.send(second)
          fin = val2.class == Date ? val2 : Date.parse(val2)
          errors.add(second, 'is before the start date') if start && fin && (fin < start)
        rescue
          errors.add(second, 'is not a valid date')
        end
      end
    end
  end

  def validate_exists(name, klass = nil)
    klass = (klass || name.sub(/_id/, "")).classify.constantize
    value = self.send(name)
    for v in [value].flatten
      errors.add(name, "cannot be found with id #{v}") if !klass.find_by_id(v)
    end
  end

  def validate_emptyness(name, varname = nil) # UGH, varname and name need a better way of handling
    varname ||= name
    if is_this_condition_enabled(name)
      value = self.send(varname)
      return ! _empty_check(varname, value)
    end
    false
  end

  def _empty_check(varname, value)
    empty = (value.nil? or ((!value.is_a?(Fixnum)) and (!value.is_a?(Bignum)) and value.empty?))
    errors.add(varname, 'cannot be blank') if empty
    empty
  end

  def parse_and_validate_list(name, varname = nil, allowzero = false)
    if is_this_condition_enabled(name)
      varname ||= name
      result = _to_a(self.send(varname), allowzero)
      self.send(varname + "=", result)
      err = result == [-1]
      errors.add(varname, 'must have at least one choice selected') if err
      return !err
    end
    false
  end

  def hard_drive_serial_number_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    return ["#{klass.table_name}.cleaned_output ILIKE ?", '%<serial>' + @hard_drive_serial_number + '</serial>%']
  end

  def processor_product_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    klass = System if klass == SpecSheet
    return ["#{klass.table_name}.processor_product LIKE ?", '%' + @processor_product + '%']
  end

  def week_conditions(klass)
    klass = VolunteerDefaultEvent if klass == VolunteerDefaultShift
    return ["(#{klass.table_name}.week IS NULL OR #{klass.table_name}.week LIKE ' ' OR #{klass.table_name}.week LIKE '' OR #{klass.table_name}.week ILIKE ?)", @week]
  end

  def schedule_conditions(klass)
    in_clause = "(-1)"
    s = Schedule.find_by_id(@schedule_id.to_i)
    if s
      in_clause = s.in_clause
    end
    in_clause += " AND (NOT actual) AND (shift_date IS NULL) AND ('#{Date.today}' BETWEEN shifts.effective_date AND shifts.ineffective_date OR shifts.ineffective_date IS NULL)" if klass == Shift
    return ["#{klass.table_name}.schedule_id IN #{in_clause}"]
  end

  def shift_type_conditions(klass)
    col = klass == WorkShift ? "kind" : "type"
    return ["#{klass.table_name}.#{col} LIKE ?", @shift_type]
  end

  def store_credit_redeemed_conditions(klass)
    raise unless klass == GizmoReturn
    return ["#{klass.table_name}.id IN (SELECT gizmo_return_id FROM store_credits WHERE gizmo_return_id IS NOT NULL AND (payment_id IS NOT NULL OR id IN (SELECT return_store_credit_id FROM gizmo_events WHERE return_store_credit_id IS NOT NULL)))"]
  end

  def effective_at_conditions(klass)
    ["(#{klass.table_name}.effective_at IS NULL OR #{klass.table_name}.effective_at <= ?) AND (#{klass.table_name}.ineffective_at IS NULL OR #{klass.table_name}.ineffective_at > ?)", @effective_at, @effective_at]
  end

  def effective_on_conditions(klass)
    klass = VolunteerDefaultShift if klass == DefaultAssignment
    ["(#{klass.table_name}.effective_on IS NULL OR #{klass.table_name}.effective_on <= ?) AND (#{klass.table_name}.ineffective_on IS NULL OR #{klass.table_name}.ineffective_on > ?)", @effective_on_end, @effective_on_start]
  end

  def worker_type_conditions(klass)
    search_date = klass.table_name + "." + klass.conditions_date_field
    search_worker_id = klass.table_name + ".worker_id"
    ["(SELECT worker_type_id FROM workers_worker_types WHERE workers_worker_types.worker_id = #{search_worker_id} AND (#{search_date} >= workers_worker_types.effective_on OR workers_worker_types.effective_on IS NULL) AND (#{search_date} <= workers_worker_types.ineffective_on OR workers_worker_types.ineffective_on IS NULL) LIMIT 1) = ?", @worker_type_id.to_i]
  end

  def sale_type_conditions(klass)
    klass = Sale if klass == GizmoEvent
    ["#{klass.table_name}.sale_type_id = ?", @sale_type_id.to_i]
  end

  def worker_conditions(klass)
    return ["#{klass.table_name}.worker_id IN (?)", (@worker_id)]
  end

  def job_conditions(klass)
    extra = [WorkShift, Shift, StandardShift].include?(klass) ? " AND (#{klass.table_name}.meeting_name IS NULL OR #{klass.table_name}.meeting_name LIKE '')" : ""
    return ["#{klass.table_name}.job_id IN (?)#{extra}", (@job_id)]
  end

  def empty_conditions(klass)
    return ["1=1"]
  end

  def cancelled_conditions(klass)
    if @cancelled == 1
      return ["1=1"]
    else
      return ["(#{klass.table_name}.attendance_type_id IS NULL OR attendance_types.cancelled = false OR attendance_types.cancelled IS NULL)"]
    end
  end

  def form_factor_conditions(klass)
    return ["#{klass.table_name}.form_factor LIKE ?", @form_factor]
  end

  def attendance_type_conditions(klass)
    return ["#{klass.table_name}.attendance_type_id = ?", @attendance_type_id.to_i]
  end

  def needs_checkin_conditions(klass)
    return ["#{klass.table_name}.attendance_type_id IS NULL"]
  end

  def assigned_conditions(klass)
    return ["#{klass.table_name}.contact_id IS NOT NULL"]
  end

  def finalized_conditions(klass)
    return ["#{klass.table_name}.finalized_on IS NOT NULL"]
  end

  def can_login_conditions(klass)
    ["#{klass.table_name}.id IN (SELECT contact_id FROM users WHERE can_login = 't')"]
  end

  def role_conditions(klass)
    ["#{klass.table_name}.id IN (SELECT contact_id FROM users WHERE can_login = 't' AND id IN (SELECT user_id FROM roles_users WHERE role_id = ?))", @role.to_i]
  end

  def action_conditions(klass)
    klass = BuilderTask if klass == SpecSheet
    ["#{klass.table_name}.action_id = ?", @action.to_i]
  end

  def type_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    klass = SpecSheet if klass == System
    ["#{klass.table_name}.type_id = ?", @type_id.to_i]
  end

  def covered_conditions(klass)
    ["gizmo_events.covered = ?", true]
  end

  def payment_amount_conditions(klass)
    # the to_s is required below because when a value of "6" is passed in
    # it is magically made into a Fixnum so the to_cents blows up
    # not sure where this magic comes from
    klass = Payment unless klass == StoreCredit
    case @payment_amount_type
    when 'between'
      return ["#{klass.table_name}.amount_cents BETWEEN ? AND ?",
              @payment_amount_low.to_s.to_cents,
              @payment_amount_high.to_s.to_cents]
    when '>='
      return ["#{klass.table_name}.amount_cents >= ?", @payment_amount_ge.to_s.to_cents]
    when '<='
      return ["#{klass.table_name}.amount_cents <= ?", @payment_amount_le.to_s.to_cents]
    when 'exact'
      return ["#{klass.table_name}.amount_cents = ?", @payment_amount_exact.to_s.to_cents]
    end
  end


  def payment_total_conditions(klass)
    # the to_s is required below because when a value of "6" is passed in
    # it is magically made into a Fixnum so the to_cents blows up
    # not sure where this magic comes from
    orig_klass = klass
    klass = Payment unless klass == StoreCredit
    t = "COALESCE((SELECT SUM(#{klass.table_name}.amount_cents) FROM #{klass.table_name} WHERE #{orig_klass.table_name.singularize}_id = #{orig_klass.table_name}.id), 0)"
    case @payment_total_type
    when 'between'
      return ["#{t} BETWEEN ? AND ?",
              @payment_total_low.to_s.to_cents,
              @payment_total_high.to_s.to_cents]
    when '>='
      return ["#{t} >= ?", @payment_total_ge.to_s.to_cents]
    when '<='
      return ["#{t} <= ?", @payment_total_le.to_s.to_cents]
    when 'exact'
      return ["#{t} = ?", @payment_total_exact.to_s.to_cents]
    end
  end

  def extract_conditions(klass)
    return ["EXTRACT( #{@extract_type} FROM #{klass.table_name}.#{@extract_field} ) = ?", @extract_value]
  end

  def generated_shift_conditions(klass)
    klass = VolunteerShift if klass == Assignment
    return ["#{klass.table_name}.volunteer_default_shift_id IS NOT NULL"]
  end

  def volunteer_task_type_conditions(klass)
    tbl = klass.table_name
    tbl = "volunteer_shifts" if tbl == "assignments"
    tbl = "volunteer_default_shifts" if tbl == "default_assignments"
    return ["#{tbl}.volunteer_task_type_id IN (?)", (@volunteer_task_type_id)]
  end

  def weekday_conditions(klass)
    klass = VolunteerDefaultEvent if klass == VolunteerDefaultShift
    klass = VolunteerDefaultEvent if klass == ResourcesVolunteerDefaultEvent
    klass = VolunteerDefaultEvent if klass == DefaultAssignment
    klass = VolunteerEvent if klass == VolunteerShift
    klass = VolunteerEvent if klass == ResourcesVolunteerEvent
    klass = VolunteerEvent if klass == Assignment
    a = (@weekday_id)
    if klass == VolunteerEvent
      return ["EXTRACT(dow FROM #{klass.table_name}.date) IN (?)", a]
    else
      return ["#{klass.table_name}.weekday_id IN (?)", a]
    end
  end

  def roster_conditions(klass)
    klass = VolunteerShift if klass == Assignment
    klass = VolunteerDefaultShift if klass == DefaultAssignment
    tbl = klass.table_name
    return ["#{tbl}.roster_id IN (?)", (@roster_id)]
  end

  def sked_conditions(klass)
    klass = VolunteerShift if klass == Assignment
    klass = VolunteerDefaultShift if klass == DefaultAssignment
    tbl = klass.table_name
    return ["#{tbl}.roster_id IN (SELECT roster_id FROM rosters_skeds WHERE sked_id = ?)", @sked_id.to_i]
  end

  def volunteer_hours_conditions(klass)
    first_part = "id IN (SELECT contact_id FROM volunteer_tasks vt JOIN contacts c ON c.id=vt.contact_id GROUP BY 1,c.next_milestone HAVING"
    case @volunteer_hours_type
    when 'between'
      return ["#{first_part} sum(duration) BETWEEN ? AND ?)",
              @volunteer_hours_low,
              @payment_amount_high]
    when '>='
      return ["#{first_part} sum(duration) >= ?)", @volunteer_hours_ge]
    when '<='
      return ["#{first_part} sum(duration) <= ?)", @volunteer_hours_le]
    when 'exact'
      return ["#{first_part} sum(duration) = ?)", @volunteer_hours_exact]
    end
  end

  def volunteered_hours_in_days_conditions(klass)
    ['contacts.id IN (SELECT contact_id FROM volunteer_tasks WHERE date_performed >= ? GROUP BY contact_id HAVING SUM(duration) >= ?)', Date.today - @volunteer_hours_days.to_i, @volunteer_hours_minimum.to_i]
  end

  def volunteered_non_court_hours_in_days_conditions(klass)
    ['contacts.id IN (SELECT contact_id FROM volunteer_tasks LEFT OUTER JOIN community_service_types ON community_service_types.id = community_service_type_id WHERE date_performed >= ? GROUP BY contact_id HAVING SUM(duration * COALESCE(community_service_types.hours_multiplier, 1)) >= ?)', Date.today - @volunteer_non_court_hours_days.to_i, @volunteer_non_court_hours_minimum.to_i]
  end

  def contract_conditions(klass)
    if klass == GizmoEvent
      ["(donations.contract_id = ? OR systems.contract_id = ? OR recycling_contract_id = ?)", @contract_id.to_i, @contract_id.to_i, @contract_id.to_i]
    elsif klass == Donation
      ["contract_id = ?", @contract_id.to_i]
    else # recyclings and disbursements
      ["(gizmo_events.system_id IN (SELECT id FROM systems WHERE contract_id = ?) OR gizmo_events.recycling_contract_id = ?)", @contract_id.to_i, @contract_id.to_i]
    end
  end

  def id_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    return ["#{klass.table_name}.id = ?", @id.to_i]
  end

  def postal_code_conditions(klass)
    return ["#{klass.table_name}.postal_code ILIKE '?%'", @postal_code]
  end

  def city_conditions(klass)
    return ["#{klass.table_name}.city ILIKE ?", @city]
  end

  def email_conditions(klass)
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_methods WHERE contact_method_type_id IN (SELECT id FROM contact_method_types WHERE description ILIKE '%email%') AND value ILIKE ?)", @email]
  end

  def phone_number_conditions(klass)
    phone_number = @phone_number.to_s.gsub(/[^[:digit:]]/, "")
    phone_number = phone_number.sub(/^(.{3})(.{3})(.{4})$/, "%\\1%\\2%\\3%")
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_methods WHERE contact_method_type_id IN (SELECT id FROM contact_method_types WHERE (description ILIKE '%phone%') OR (description ILIKE '%fax%')) AND value ILIKE ?)", phone_number]
  end

  def contact_type_conditions(klass)
    if klass == Contact
      i = "id"
    else
      i = "contact_id"
    end
    return ["#{klass.table_name}.#{i} IN (SELECT contact_id FROM contact_types_contacts WHERE contact_type_id = ?)", @contact_type.to_i]
  end

  def organization_name_conditions(klass)
    return ["#{klass.table_name}.organization ILIKE ('%' || ? || '%')", @organization_name]
  end

  def organization_conditions(klass)
    if klass == Contact
      i = "id"
    else
      i = "contact_id"
    end
    return ["#{klass.table_name}.#{i} IN (SELECT id FROM contacts WHERE is_organization = ?)", true]
  end

  def is_pickup_conditions(klass)
    if klass == GizmoEvent
      return ["(#{klass.table_name}.donation_id IS NOT NULL AND donations.is_pickup = ?)", true]
    else
      return ["#{klass.table_name}.is_pickup = ?", true]
    end
  end

  def needs_attention_conditions(klass)
    return ["#{klass.table_name}.needs_attention = 't'"]
  end

  def anonymous_conditions(klass)
    return ["#{klass.table_name}.postal_code IS NOT NULL AND #{klass.table_name}.contact_id IS NULL"]
  end

  def unresolved_shipment_conditions(klass)
    return ["#{klass.table_name}.resolved_at IS NULL"]
  end

  def unresolved_invoices_conditions(klass)
    return ["#{klass.table_name}.invoice_resolved_at IS NULL" +
            " AND payments.payment_method_id = ?",
            PaymentMethod.find_by_description('invoice')
           ]
  end

  def flagged_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    return ["#{klass.table_name}.flag = 't'"]
  end

  def system_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    if klass == Sale or klass == Disbursement
      return ["? IN (gizmo_events.system_id)", @system_id.to_i]
    else
      return ["#{klass.table_name}.system_id = ?", @system_id.to_i]
    end
  end

  def worked_at_conditions(klass)
    a = date_range(VolunteerTask, 'date_performed', 'worked_at')
    b = a[0]
    a[0] = "id IN (SELECT contact_id FROM volunteer_tasks WHERE #{b})"
    a
  end

  def received_at_conditions(klass)
    a = date_range(Disbursement, 'disbursed_at', 'received_at')
    b = a[0]
    a[0] = "id IN (SELECT contact_id FROM disbursements WHERE #{b})"
    a
  end

  def bought_at_conditions(klass)
    a = date_range(Sale, 'created_at', 'bought_at')
    b = a[0]
    a[0] = "id IN (SELECT contact_id FROM sales WHERE #{b})"
    a
  end

  def donated_at_conditions(klass)
    a = date_range(Donation, 'created_at', 'donated_at')
    b = a[0]
    a[0] = "id IN (SELECT contact_id FROM donations WHERE #{b})"
    a
  end

  def date_conditions(klass)
    klass = VolunteerShift if klass == Assignment
    klass = VolunteerEvent if klass == VolunteerShift
    klass = VolunteerEvent if klass == ResourcesVolunteerEvent
    date_range(klass, 'date', 'date')
  end

  def shift_date_conditions(klass)
    date_range(klass, 'shift_date', 'shift_date')
  end

  def occurred_at_conditions(klass)
    klass = GizmoEvent if [Recycling, Disbursement].include?(klass) # Donation, Sale, GizmoReturn
    date_range(klass, 'occurred_at', 'occurred_at')
  end

  def created_at_conditions(klass)
    date_range(klass, 'created_at', 'created_at')
  end

  def updated_at_conditions(klass)
    date_range(klass, 'updated_at', 'updated_at')
  end

  def last_volunteer_date_conditions(klass)
    ret = date_range(klass, 'MAX(date_performed)', 'last_volunteer_date')
    ret[0] = "id IN (SELECT contact_id FROM volunteer_tasks GROUP BY contact_id HAVING #{ret[0].gsub(/contacts.MAX/, "MAX")})"
    return ret
  end

  def last_donated_date_conditions(klass)
    ret = date_range(klass, 'MAX(donations.occurred_at)', 'last_donated_date')
    ret[0] = "id IN (SELECT contact_id FROM donations GROUP BY contact_id HAVING #{ret[0].gsub(/contacts.MAX/, "MAX")})"
    return ret
  end

  def last_donated_contribution_only_date_conditions(klass)
    ret = date_range(klass, 'MAX(donations.occurred_at)', 'last_donated_contribution_only_date')
    ret[0] = "id IN (SELECT contact_id FROM donations WHERE donations.id IN (SELECT DISTINCT donation_id FROM payments WHERE donation_id IS NOT NULL) AND donations.id NOT IN (SELECT DISTINCT donation_id FROM gizmo_events WHERE donation_id IS NOT NULL) GROUP BY contact_id HAVING #{ret[0].gsub(/contacts.MAX/, "MAX")})"
    return ret
  end

  def last_donated_gizmos_only_date_conditions(klass)
    ret = date_range(klass, 'MAX(donations.occurred_at)', 'last_donated_gizmos_only_date')
    ret[0] = "id IN (SELECT contact_id FROM donations WHERE donations.id NOT IN (SELECT DISTINCT donation_id FROM payments WHERE donation_id IS NOT NULL) AND donations.id IN (SELECT DISTINCT donation_id FROM gizmo_events WHERE donation_id IS NOT NULL) GROUP BY contact_id HAVING #{ret[0].gsub(/contacts.MAX/, "MAX")})"
    return ret
  end

  def last_build_conditions(klass)
    date_range(klass, 'last_build', 'last_build')
  end

  def date_performed_conditions(klass)
    date_range(klass, 'date_performed', 'date_performed')
  end

  def recycled_at_conditions(klass)
    date_range(klass, 'recycled_at', 'recycled_at')
  end

  def disbursed_at_conditions(klass)
    date_range(klass, 'disbursed_at', 'disbursed_at')
  end

  def created_by_conditions(klass)
    ["#{klass.table_name}.created_by = ?", @created_by]
  end

  def signed_off_by_conditions(klass)
    ["#{klass.table_name}.cashier_signed_off_by = ?", @signed_off_by]
  end

  def updated_by_conditions(klass)
    ["#{klass.table_name}.updated_by = ?", @updated_by]
  end

  def cashier_updated_by_conditions(klass)
    ["#{klass.table_name}.cashier_updated_by = ?", @cashier_updated_by]
  end

  def cashier_created_by_conditions(klass)
    ["#{klass.table_name}.cashier_created_by = ?", @cashier_created_by]
  end

  # TODO: should this be in conditions_base? and the html part that's
  # in html_helper in conditions_base_helper? YES!
  def date_range(klass, db_field, condition_name)
    field = condition_name
    case eval("@#{field}_date_type")
    when 'daily'
      start_date = Date.parse(eval("@#{field}_date").to_s)
      end_date = start_date + 1
    when 'monthly'
      year = (eval("@#{field}_year") || Date.today.year).to_i
      start_date = Time.local(year, eval("@#{field}_month"), 1)
      if eval("@#{field}_month").to_i == 12
        end_month = 1
        end_year = year + 1
      else
        end_month = 1 + eval("@#{field}_month").to_i
        end_year = year
      end
      end_date = Time.local(end_year, end_month, 1)
    when 'quarterly'
      quarter = eval("@#{field}_quarter")
      year = eval("@#{field}_year_q")
      start_date = Time.local(year, (quarter * 3) - 2, 1)
      end_year = year
      end_month = (quarter * 3) - 2
      end_month += 3
      if end_month > 12
        end_month -= 12
        end_year += 1
      end
      end_date = Time.local(end_year, end_month, 1)
    when 'yearly'
      year = eval("@#{field}_year_only")
      start_date = Time.local(year, 1, 1)
      end_date = Time.local(year + 1, 1, 1)
    when 'arbitrary'
      stds = eval("@#{field}_start_date").to_s
      start_date = stds.length == 0 ? nil : Date.parse(stds)
      ends = eval("@#{field}_end_date").to_s
      end_date = ends.length == 0 ? nil : (Date.parse(ends) + 1)
    end
    column_name = db_field
    conds = []
    opts = []
    unless start_date.nil?
      opts << start_date
      conds << "#{klass.table_name}.#{column_name} >= ?"
    end
    unless end_date.nil?
      opts << end_date
      conds << "#{klass.table_name}.#{column_name} < ?"
    end
    return [ conds.join(" AND "),
             *opts ]
  end

  def contact_conditions(klass)
    klass = BuilderTask if klass == SpecSheet
    @contact_id = @contact_id.to_i
    if klass == GizmoEvent
      return ["(sales.contact_id = ? OR donations.contact_id = ? OR gizmo_returns.contact_id = ? OR disbursements.contact_id = ?)", contact_id.to_i, contact_id.to_i, contact_id.to_i, contact_id.to_i] # NOT OR recyclings.contact_id = ?
    else
      return [ "#{klass.table_name}.contact_id = ?", contact_id.to_i ]
    end
  end

  def payment_method_conditions(klass)
    if klass.new.respond_to?(:payments)
      return [ "payments.payment_method_id = ?", payment_method_id.to_i ]
    else
      return [ "#{klass.table_name}.id IS NULL" ]
    end
  end

  def _to_a(input, allow_zero = false)
    list = [input].flatten.map{|x| x.to_i}.select{|x| (!x.nil?) and (allow_zero || x != 0)}
    return [-1] if list.length == 0
    list
  end

  def gizmo_type_id_conditions(klass)
    return ["gizmo_events.gizmo_type_id IN (?)", (@gizmo_type_id)]
  end

  def program_id_conditions(klass)
    return ["#{klass.table_name}.program_id IN (?)", (@program_id)]
  end

  def gizmo_context_id_conditions(klass)
    raise unless klass == System
    return ["#{klass.table_name}.id IN (SELECT DISTINCT system_id FROM gizmo_events WHERE gizmo_context_id = ?)", (@gizmo_context_id)]
  end

  def gizmo_type_group_id_conditions(klass)
    return ["gizmo_events.gizmo_type_id IN (SELECT gizmo_type_id FROM gizmo_type_groups_gizmo_types WHERE gizmo_type_group_id IN (?))", (gizmo_type_group_id)]
  end

  def vendor_conditions(klass)
    return ['vendor ILIKE ?', '%' + @vendor.to_s + '%']
  end

  def model_conditions(klass)
    return ['model ILIKE ?', '%' + @model.to_s + '%']
  end

  def interface_type_conditions(klass)
    return ['bus_type LIKE ?', @interface_type.to_s]
  end

  def result_conditions(klass)
    return ['result LIKE ?', @result.to_s]
  end

  MEGABYTES_UNITS = {"MB" => 1, "GB" => 1000, "TB" => (1000 * 1000)}
  def megabytes_size_conditions(klass)
    factor = MEGABYTES_UNITS[@megabytes_size_units]
    case @megabytes_size_type
    when 'between'
      return ["#{klass.table_name}.megabytes_size BETWEEN ? AND ?",
              @megabytes_size_low.to_f * factor,
              @megabytes_size_high.to_f * factor]
    when '>='
      return ["#{klass.table_name}.megabytes_size >= ?", @megabytes_size_ge.to_f * factor]
    when '<='
      return ["#{klass.table_name}.megabytes_size <= ?", @megabytes_size_le.to_f * factor]
    when 'exact'
      return ["#{klass.table_name}.megabytes_size = ?", @megabytes_size_exact.to_f * factor]
    end
  end

  def serial_number_conditions(klass)
    klass = SpecSheet if klass == BuilderTask
    if klass == SpecSheet
      return ["#{klass.table_name}.system_id IN (SELECT id FROM systems WHERE ? IN (system_serial_number, mobo_serial_number, serial_number))", @serial_number.to_s]
    elsif klass == DisktestRun
      return ["serial_number ILIKE ?", '%' + @serial_number.to_s + '%']
    else
      raise
    end
  end

  def logged_in_within_conditions(klass)
    return ['id IN (SELECT contact_id FROM users WHERE contact_id IS NOT NULL AND last_logged_in >= ?)', @logged_in_within.months.ago.to_date]
  end

  def contribution_conditions(klass)
    return ["(SELECT count(*) from gizmo_events WHERE #{klass.table_name.singularize}_id = #{klass.table_name}.id) = 0"]
  end

  def gizmo_category_id_conditions(klass)
    return ["(SELECT gizmo_category_id FROM gizmo_types WHERE id = gizmo_events.gizmo_type_id) = ?", gizmo_category_id.to_i]
  end

  def disbursement_type_id_conditions(klass)
    klass = Disbursement if klass == GizmoEvent
    return ["#{klass.table_name}.disbursement_type_id IN (?)", disbursement_type_id]
  end

  def store_credit_id_conditions(klass)
    tid = -1
    begin
      tid = StoreChecksum.new_from_checksum(store_credit_id).result
    rescue StoreChecksumException
    end
    if klass == GizmoReturn
      return ["#{klass.table_name}.id IN (SELECT #{klass.table_name.singularize}_id FROM store_credits WHERE id = ?)", tid]
    elsif klass == Sale
      return ["payments.id = (SELECT payment_id FROM store_credits WHERE id = ?)", tid]
    elsif klass == StoreCredit
      return ["id = ?", tid]
    else
      raise
    end
  end

  def some_date_enabled
    DATES.each{|x|
      if eval("@#{x}_enabled") == "true"
        return x
      end
    }
    return false
  end

  def contact
    if contact_id && !contact_id.to_s.empty?
      if( (! @contact) || (contact_id != @contact.id) )
        @contact = Contact.find_by_id(contact_id.to_i)
      end
    else
      @contact = nil
    end
    return @contact
  end

  def worker
    if worker_id && !worker_id.to_s.empty?
      if( (! @worker) || (worker_id != @worker.id) )
        @worker = Worker.find(worker_id)
      end
    else
      @worker = nil
    end
    return @worker
  end

  def to_s
    return skedj_to_s("sentence")
  end

  # TODO: move the "during" part here, ( eval("@#{which_date}_date_type") == "daily" ? " on " : " during ")
  # TODO: move into skedj_to_s once they are integrated
  def date_range_to_s(thing)
    case eval("@" + thing + "_date_type")
    when 'daily'
      desc = Date.parse(eval("@" + thing + "_date").to_s).to_s
    when 'monthly'
      year = (eval("@" + thing + "_year") || Date.today.year).to_i
      start_date = Time.local(year, eval("@" + thing + "_month"), 1)
      desc = "%s, %i" % [ Date::MONTHNAMES[start_date.month], year ]
    when 'quarterly'
      year = eval("@" + thing + "_year_q")
      quarter = eval("@" + thing + "_quarter")
      desc = 'quarter %i of %i' % [ quarter, year ]
    when 'yearly'
      year = eval("@" + thing + "_year_only")
      desc = '%i' % [ year ]
    when 'arbitrary'
#      start_date = Date.parse(eval("@" + thing + "_start_date").to_s)
#      end_date = Date.parse(eval("@" + thing + "_end_date").to_s)
      stds = eval("@" + thing + "_start_date")
      stds = "Beginning of time" if stds.length == 0
      ends = eval("@" + thing + "_end_date")
      ends = "End of time" if ends.length == 0
      desc = "#{stds} to #{ends}"
    else
      desc = 'unknown date type'
    end
    return desc
  end

  def skedj_to_s(style = "before", show_date = false, ignores = [])
    return "" if CONDS.select{|x| is_this_condition_enabled(x)}.length == 0
    if !self.valid?
      return "with invalid search conditions"
    end
    show_date = show_date || (style == "sentence")
    mea = self.methods
    ta = mea.select{|x| x != 'is_this_condition_enabled' && x.match(/_enabled$/)}.select{|x| self.send(x.to_sym) == "true"} # TODO: look at CONDS instead
    dv = nil
    ret = ta.map{|t|
      meo = me = t.sub(/_enabled$/, "")
      if ignores.include?(me)
        nil
      else
      v = ""
      if DATES.include?(me)
        mv = date_range_to_s(me)
        if dv.nil? and (style == "sentence")
          dv = mv
        else
          v = mv if show_date
        end
      elsif CHECKBOXES.include?(me)
        v = self.send(me) == 1
      elsif me == 'volunteered_hours_in_days'
        v = "volunteering #{@volunteer_hours_minimum} hours in last #{@volunteer_hours_days} days"
      elsif me == 'volunteered_non_court_hours_in_days'
        v = "volunteering #{@volunteer_hours_minimum} non-court hours in last #{@volunteer_hours_days} days"
      elsif meo == 'contact' or meo == 'worker' or meo == 'contact_type' or !mea.include?(me) or meo.match(/_id/)
        ome = me.dup
        me += "_id" unless me.match(/_id/)
        ome = me unless ome == 'contact_type' # FIXME: this is ugly
        meo = meo.sub(/_id/, "")
        if !mea.include?(ome)
          v = ""
        else
          v = [self.send(ome)].flatten.map{|it|
            obj = meo.classify.constantize.find_by_id(it.to_i)
            sendit = obj.respond_to?(:condition_to_s) ? :condition_to_s : obj.respond_to?(:description) ? :description : obj.respond_to?(:name) ? :name : :to_s
              obj.nil? ? nil : obj ? obj.send(sendit) : nil
          }.select{|x| !x.nil?}.join(",")
        end
      else
        v = self.send(me)
      end
      res = nil
      if CHECKBOXES.include?(me)
        res = (v ? "" : " not ") + " " + meo.humanize
      elsif (v && v.respond_to?(:length) && v.length > 0)
        if style == "before"
          res = (meo.humanize + ": " + v.to_s)
        else
          if ['volunteered_hours_in_days', 'volunteered_non_court_hours_in_days'].include?(meo)
            res = v.to_s
          else
            res = (v.to_s + " (" + meo.humanize + ")")
          end
        end
        if instance_variable_get("@#{meo}_excluded")
          res = "Excluding " + res
        end
      end
        res
      end
    }.select{|x| !!x}.join(style == "sentence" ? " " : ", ")
    if style == "sentence"
      ret = "for " + ret if ret.length > 0
      if show_date
        ret += " during " + dv if dv
      end
    end
    ret
  end
end
