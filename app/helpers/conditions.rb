class Conditions < ConditionsBase
  DATES = %w[
      created_at recycled_at disbursed_at received_at
      worked_at bought_at date_performed donated_at occurred_at
  ]

  CONDS = (%w[
      id contact_type needs_attention anonymous unresolved_invoices
      payment_method payment_amount gizmo_type_id gizmo_category_id covered
      postal_code city phone_number contact volunteer_hours email
      flagged system contract created_by cashier_created_by extract
      empty disbursement_type_id store_credit_id organization
      can_login role action worker
    ] + DATES).uniq

  for i in CONDS
    attr_accessor (i + "_enabled").to_sym
  end

  for i in DATES
    attr_accessor (i + '_date').to_sym, (i + '_date_type').to_sym, (i + '_start_date').to_sym, (i + '_end_date').to_sym, (i + '_month').to_sym, (i + '_year').to_sym
  end

  attr_accessor :worker_id

  attr_accessor :created_by, :cashier_created_by

  attr_accessor :covered

  attr_accessor :contact_id

  attr_accessor :contract_id

  attr_accessor :payment_method_id

  attr_accessor :id

  attr_accessor :system_id

  attr_accessor :needs_attention

  attr_accessor :anonymous

  attr_accessor :unresolved_invoices

  attr_accessor :gizmo_type_id

  attr_accessor :gizmo_category_id

  attr_accessor :payment_amount_type, :payment_amount_exact, :payment_amount_low, :payment_amount_high, :payment_amount_ge, :payment_amount_le

  attr_accessor :contact_type

  attr_accessor :is_organization

  attr_accessor :city, :postal_code, :phone_number, :email

  attr_accessor :volunteer_hours_type, :volunteer_hours_exact, :volunteer_hours_low, :volunteer_hours_high, :volunteer_hours_ge, :volunteer_hours_le

  attr_accessor :extract_type, :extract_value, :extract_field

  attr_accessor :disbursement_type_id

  attr_accessor :store_credit_id

  attr_accessor :role

  attr_accessor :action

  def contact
    if contact_id && !contact_id.to_s.empty?
      if( (! @contact) || (contact_id != @contact.id) )
        @contact = Contact.find(contact_id)
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


  def worker_conditions(klass)
    return ["worker_id = ?", @worker_id]
  end

  def empty_conditions(klass)
    return ["1=1"]
  end

  def join_conditions(conds_a, conds_b)
    raise ArgumentError.new("'#{conds_a}' is empty") if conds_a.empty?
    raise ArgumentError.new("'#{conds_b}' is empty") if conds_b.empty?
    return [
            conds_a[0].to_s +
            (conds_a[0].empty? ? '' : ' AND ') +
            conds_b[0].to_s
           ] + conds_a[1..-1] + conds_b[1..-1]
  end

  def can_login_conditions(klass)
    ["#{klass.table_name}.id IN (SELECT contact_id FROM users WHERE can_login = 't')"]
  end

  def role_conditions(klass)
    ["#{klass.table_name}.id IN (SELECT contact_id FROM users WHERE can_login = 't' AND id IN (SELECT user_id FROM roles_users WHERE role_id = ?))", @role]
  end

  def action_conditions(klass)
    ["#{klass.table_name}.action_id = ?", @action]
  end

  def covered_conditions(klass)
    ["gizmo_events.covered = ?", @covered != 0]
  end

  def payment_amount_conditions(klass)
    # the to_s is required below because when a value of "6" is passed in
    # it is magically made into a Fixnum so the to_cents blows up
    # not sure where this magic comes from
    case @payment_amount_type
    when 'between'
      return ["payments.amount_cents BETWEEN ? AND ?",
              @payment_amount_low.to_s.to_cents,
              @payment_amount_high.to_s.to_cents]
    when '>='
      return ["payments.amount_cents >= ?", @payment_amount_ge.to_s.to_cents]
    when '<='
      return ["payments.amount_cents <= ?", @payment_amount_le.to_s.to_cents]
    when 'exact'
      return ["payments.amount_cents = ?", @payment_amount_exact.to_s.to_cents]
    end
  end

  def extract_conditions(klass)
    return ["EXTRACT( #{@extract_type} FROM #{klass.table_name}.#{@extract_field} ) = ?", @extract_value]
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

  def contract_conditions(klass)
    if klass == GizmoEvent
      ["(donations.contract_id = ? OR systems.contract_id = ? OR recycling_contract_id = ?)", @contract_id, @contract_id, @contract_id]
    elsif klass == Donation
      ["contract_id = ?", @contract_id]
    else # recyclings and disbursements
      ["(gizmo_events.system_id IN (SELECT id FROM systems WHERE contract_id = ?) OR gizmo_events.recycling_contract_id = ?)", @contract_id, @contract_id]
    end
  end

  def id_conditions(klass)
    return ["#{klass.table_name}.id = ?", @id]
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
    if phone_number.length != 10
      @phone_number = "INVALID PHONE NUMBER(MUST BE 10 DIGITS LONG)...IGNORED"
      return [""]
    end
    phone_number = phone_number.sub(/^(.{3})(.{3})(.{4})$/, "%\\1%\\2%\\3%")
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_methods WHERE contact_method_type_id IN (SELECT id FROM contact_method_types WHERE (description ILIKE '%phone%') OR (description ILIKE '%fax%')) AND value ILIKE ?)", phone_number]
  end

  def contact_type_conditions(klass)
    if klass == Contact
      i = "id"
    else
      i = "contact_id"
    end
    return ["#{klass.table_name}.#{i} IN (SELECT contact_id FROM contact_types_contacts WHERE contact_type_id = ?)", @contact_type]
  end

  def organization_conditions(klass)
    if klass == Contact
      i = "id"
    else
      i = "contact_id"
    end
    return ["#{klass.table_name}.#{i} IN (SELECT id FROM contacts WHERE is_organization = ?)", (@is_organization > 0) ? true : false]
  end

  def needs_attention_conditions(klass)
    return ["#{klass.table_name}.needs_attention = 't'"]
  end

  def anonymous_conditions(klass)
    return ["#{klass.table_name}.postal_code IS NOT NULL AND #{klass.table_name}.contact_id IS NULL"]
  end

  def unresolved_invoices_conditions(klass)
    return ["#{klass.table_name}.invoice_resolved_at IS NULL" +
            " AND payments.payment_method_id = ?",
            PaymentMethod.find_by_description('invoice')
           ]
  end

  def flagged_conditions(klass)
    return ["#{klass.table_name}.flag = 't'"]
  end

  def system_conditions(klass)
    if klass == Sale or klass == Disbursement
      return ["? IN (gizmo_events.system_id)", @system_id]
    else
      return ["#{klass.table_name}.system_id = ?", @system_id]
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

  def occurred_at_conditions(klass)
    date_range(klass, 'occurred_at', 'occurred_at')
  end

  def created_at_conditions(klass)
    date_range(klass, 'created_at', 'created_at')
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
    ["created_by = ?", @created_by]
  end

  def cashier_created_by_conditions(klass)
    ["cashier_created_by = ?", @cashier_created_by]
  end

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
    when 'arbitrary'
      start_date = Date.parse(eval("@#{field}_start_date").to_s)
      end_date = Date.parse(eval("@#{field}_end_date").to_s) + 1
    end
    column_name = db_field
    return [ "#{klass.table_name}.#{column_name} >= ? AND #{klass.table_name}.#{column_name} < ?",
             start_date, end_date ]
  end

  def contact_conditions(klass)
    return [ "#{klass.table_name}.contact_id = ?", contact_id ]
  end

  def payment_method_conditions(klass)
    if klass.new.respond_to?(:payments)
      return [ "payments.payment_method_id = ?", payment_method_id ]
    else
      return [ "#{klass.table_name}.id IS NULL" ]
    end
  end

  def gizmo_type_id_conditions(klass)
    return ["gizmo_events.gizmo_type_id=?", gizmo_type_id]
  end

  def gizmo_category_id_conditions(klass)
    return ["(SELECT gizmo_category_id FROM gizmo_types WHERE id = gizmo_events.gizmo_type_id) = ?", gizmo_category_id]
  end

  def disbursement_type_id_conditions(klass)
    return ["#{klass.table_name}.disbursement_type_id = ?", disbursement_type_id]
  end

  def store_credit_id_conditions(klass)
    if klass == GizmoReturn
      return ["#{klass.table_name}.id IN (SELECT #{klass.table_name.singularize}_id FROM store_credits WHERE id = ?)", store_credit_id]
    elsif klass == Sale
      return ["payments.id = (SELECT payment_id FROM store_credits WHERE id = ?)", store_credit_id]
    else
      raise NoMethodError
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

  def to_s
    string = ""
    contact_or_worker = @contact_enabled=="true" || @worker_enabled == "true"
    if (which_date = some_date_enabled) && contact_or_worker
      string = " by " + contact_to_s + ( eval("@#{which_date}_date_type") == "daily" ? " on " : " during ") + date_range_to_s(which_date)
    elsif (which_date = some_date_enabled)
      string = ( eval("@#{which_date}_date_type") == "daily" ? " for " : " during ") + date_range_to_s(which_date)
    elsif(contact_or_worker)
      string = " by " + contact_to_s
    else
      string = ""
    end
    if @contract_enabled == "true"
      string += " " if string.length > 0
      string += "for contract \"#{Contract.find_by_id(@contract_id).description}\""
    end
    if @covered_enabled == "true"
      string += " " if string.length > 0
      string += "for #{covered == 0 ? "un" : ""}covered items"
    end
    string
  end

  def date_range_to_s(thing)
    case eval("@" + thing + "_date_type")
    when 'daily'
      desc = Date.parse(eval("@" + thing + "_date").to_s).to_s
    when 'monthly'
      year = (eval("@" + thing + "_year") || Date.today.year).to_i
      start_date = Time.local(year, eval("@" + thing + "_month"), 1)
      desc = "%s, %i" % [ Date::MONTHNAMES[start_date.month], year ]
    when 'arbitrary'
      start_date = Date.parse(eval("@" + thing + "_start_date").to_s)
      end_date = Date.parse(eval("@" + thing + "_end_date").to_s)
      desc = "#{eval("@" + thing + "_start_date")} to #{eval("@" + thing + "_end_date")}"
    else
      desc = 'unknown date type'
    end
    return desc
  end

  def contact_to_s # "Report of hours worked for ..."
    if @contact_enabled=="true"
      return contact.display_name
    elsif  @worker_enabled == "true"
      return worker.name # HERE
    else
      return "ERROR"
    end
  end
end
