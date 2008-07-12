class Conditions
  def initialize
    @created_at_date = Date.today
    @created_at_date_type = 'daily'
    @created_at_month = Date.today
    @created_at_year = Date.today

    @recycled_at_date = Date.today
    @recycled_at_date_type = 'daily'
    @recycled_at_month = Date.today
    @recycled_at_year = Date.today

    @disbursed_at_date = Date.today
    @disbursed_at_date_type = 'daily'
    @disbursed_at_month = Date.today
    @disbursed_at_year = Date.today

    @received_at_date = Date.today
    @received_at_date_type = 'daily'
    @received_at_month = Date.today
    @received_at_year = Date.today

    @occurred_at_date = Date.today
    @occurred_at_date_type = 'daily'
    @occurred_at_month = Date.today
    @occurred_at_year = Date.today

    @worked_at_date = Date.today
    @worked_at_date_type = 'daily'
    @worked_at_month = Date.today
    @worked_at_year = Date.today

    @bought_at_date = Date.today
    @bought_at_date_type = 'daily'
    @bought_at_month = Date.today
    @bought_at_year = Date.today

    @donated_at_date = Date.today
    @donated_at_date_type = 'daily'
    @donated_at_month = Date.today
    @donated_at_year = Date.today

    @payment_method_id = PaymentMethod.cash.id
  end

  attr_accessor :created_at_date, :created_at_date_type, :created_at_start_date, :created_at_end_date, :created_at_month, :created_at_year, :created_at_enabled
  attr_accessor :recycled_at_date, :recycled_at_date_type, :recycled_at_start_date, :recycled_at_end_date, :recycled_at_month, :recycled_at_year, :recycled_at_enabled
  attr_accessor :disbursed_at_date, :disbursed_at_date_type, :disbursed_at_start_date, :disbursed_at_end_date, :disbursed_at_month, :disbursed_at_year, :disbursed_at_enabled
  attr_accessor :occurred_at_date, :occurred_at_date_type, :occurred_at_start_date, :occurred_at_end_date, :occurred_at_month, :occurred_at_year, :occurred_at_enabled
  attr_accessor :worked_at_date, :worked_at_date_type, :worked_at_start_date, :worked_at_end_date, :worked_at_month, :worked_at_year, :worked_at_enabled
  attr_accessor :bought_at_date, :bought_at_date_type, :bought_at_start_date, :bought_at_end_date, :bought_at_month, :bought_at_year, :bought_at_enabled
  attr_accessor :received_at_date, :received_at_date_type, :received_at_start_date, :received_at_end_date, :received_at_month, :received_at_year, :received_at_enabled
  attr_accessor :donated_at_date, :donated_at_date_type, :donated_at_start_date, :donated_at_end_date, :donated_at_month, :donated_at_year, :donated_at_enabled

  attr_accessor :contact_id, :contact_enabled

  attr_accessor :payment_method_id, :payment_method_enabled

  attr_accessor :id, :id_enabled

  attr_accessor :needs_attention, :needs_attention_enabled

  attr_accessor :anonymous, :anonymous_enabled

  attr_accessor :unresolved_invoices, :unresolved_invoices_enabled

  attr_accessor :gizmo_type_id, :gizmo_type_id_enabled

  attr_accessor :payment_amount_enabled, :payment_amount_type, :payment_amount_exact, :payment_amount_low, :payment_amount_high, :payment_amount_ge, :payment_amount_le

  attr_accessor :contact_type, :contact_type_enabled

  attr_accessor :city, :postal_code, :phone_number, :email, :city_enabled, :postal_code_enabled, :phone_number_enabled, :email_enabled

  attr_accessor :volunteer_hours_type, :volunteer_hours_exact, :volunteer_hours_low, :volunteer_hours_high, :volunteer_hours_ge, :volunteer_hours_le, :volunteer_hours_enabled

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

  def apply_conditions(options)
    options.each do |name,val|
      val = val.to_i if( val.to_i.to_s == val )
      self.send(name+"=", val)
    end
    return options
  end

  def conditions(klass)
    conds = %w[
      id contact_type needs_attention anonymous
      unresolved_invoices created_at payment_method
      payment_amount gizmo_type_id postal_code
      city phone_number contact volunteer_hours
      email disbursed_at donated_at occurred_at
      worked_at bought_at received_at
    ].inject([""]) {|condition_array,this_condition|
      if instance_variable_get("@#{this_condition}_enabled") == "true"
        join_conditions(condition_array,
                        self.send("#{this_condition}_conditions",
                                  klass))
      else
        condition_array
      end
    }
    if conds[0].empty?
      conds[0]="#{klass.table_name}.id = -1"
    end
    return conds
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
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_methods WHERE contact_method_type_id IN (SELECT id FROM contact_method_types WHERE description ILIKE '%email%') AND description ILIKE ?)", @email]
  end

  def phone_number_conditions(klass)
    phone_number = @phone_number.to_s.gsub(/[^[:digit:]]/, "")
    if phone_number.length != 10
      @phone_number = "INVALID PHONE NUMBER(MUST BE 10 DIGITS LONG)...IGNORED"
      return [""]
    end
    phone_number = phone_number.sub(/^(.{3})(.{3})(.{4})$/, "%\\1%\\2%\\3%")
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_methods WHERE contact_method_type_id IN (SELECT id FROM contact_method_types WHERE (description ILIKE '%phone%') OR (description ILIKE '%fax%')) AND description ILIKE ?)", phone_number]
  end

  def contact_type_conditions(klass)
    return ["#{klass.table_name}.id IN (SELECT contact_id FROM contact_types_contacts WHERE contact_type_id = ?)", @contact_type]
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

  def recycled_at_conditions(klass)
    date_range(klass, 'recycled_at', 'recycled_at')
  end

  def disbursed_at_conditions(klass)
    date_range(klass, 'disbursed_at', 'disbursed_at')
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

  def to_s
    if @created_at_enabled=="true" && @contact_enabled=="true"
      " by " + contact_to_s(show_contact_name) + ( @date_type == "daily" ? " on " : " during ") + date_range_to_s
    elsif(@created_at_enabled=="true")
      ( @date_type == "daily" ? " on " : " during ") + date_range_to_s
    elsif(@contact_enabled=="true")
      " by " + contact_to_s
    else
      ""
    end
  end

  def date_range_to_s
    case @created_at_date_type
    when 'daily'
      desc = Date.parse(@created_at_date.to_s).to_s
    when 'monthly'
      year = (@created_at_year || Date.today.year).to_i
      start_date = Time.local(year, @created_at_month, 1)
      desc = "%s, %i" % [ Date::MONTHNAMES[start_date.month], year ]
    when 'arbitrary'
      start_date = Date.parse(@created_at_start_date.to_s)
      end_date = Date.parse(@created_at_end_date.to_s)
      desc = "#{created_at_start_date} to #{created_at_end_date}"
    else
      desc = 'unknown date type'
    end
    return desc
  end

  def contact_to_s # "Report of hours worked for ..."
    return contact.display_name
  end
end
