module GizmoTransaction
  def usable_gizmo_types
    if self.gizmo_context == GizmoContext.gizmo_return
      if self.sale
        return GizmoContext.sale.gizmo_types.effective_on(self.sale.occurred_at)
      elsif self.disbursement
        return GizmoContext.disbursement.gizmo_types.effective_on(self.disbursement.occurred_at)
      else
        return (GizmoContext.disbursement.gizmo_types + GizmoContext.sale.gizmo_types).uniq
      end
    else
      return self.gizmo_context.gizmo_types.effective_on(self.occurred_at || Date.today)
    end
  end

  def showable_gizmo_types
    (self.gizmo_types + self.usable_gizmo_types).uniq.sort_by(&:description)
  end

  def gizmos
    gizmo_events.map {|ge| ge.display_name}.join(', ')
  end

  def payment
    if payments.empty?
      "free"
    else
      payments.join( ", " )
    end
  end

  def calculated_subtotal_cents
    gizmo_events.inject(0) {|tot,gizmo|
      tot + gizmo.total_price_cents
    }
  end

  def real_payments
    payments.select {|payment| payment.payment_method_id != PaymentMethod.invoice.id}
  end

  def displayed_payment_method
    found = payments.map {|payment| payment.type_description}.uniq
    t = ""
    if found.length > 1
      t = "mixed"
    elsif found.length == 1
      t = found.first # will be one of: unresolved_invoice, resolved_invoice, cash, check, coupon, credit, store_credit
    else # length < 1
      t = "free"
    end
    return t + "_transaction"
  end

  def invoices
    payments.select {|payment| payment.payment_method_id == PaymentMethod.invoice.id}
  end

  def money_tendered_cents
    amount_from_some_payments(real_payments)
  end

  def amount_from_some_payments(arr)
    return arr.inject(0) {|total,payment| total + payment.amount_cents}
  end

  def amount_invoiced_cents
    invoices.inject(0) {|total,payment| total + payment.amount_cents}
  end

  def invoiced?
    return if ! self.respond_to?(:payments)
    payments.detect {|payment| payment.payment_method_id == PaymentMethod.invoice.id}
  end

  def invoice_resolved?
    return !invoice_resolved_at.nil? && invoiced?
  end

  def total_paid?
    money_tendered_cents >= calculated_total_cents
  end

  def overpaid?
    calculated_total_cents < money_tendered_cents
  end

  def contact_information
    if contact
      contact.p_id
    elsif postal_code
      ["Anonymous (#{postal_code})"]
    else
      ["Dumped"]
    end
  end

  def contact_information_web
    if contact
      contact.display_name
    elsif postal_code
      ["Anonymous (#{postal_code})"]
    else
      ["Dumped"]
    end
  end

  def hidable_contact_information
    if contact
      contact.display_name_address
    else
      return ""
    end
  end

  def should_i_hide_it?
    if gizmo_context == GizmoContext.donation
      return true
    elsif gizmo_context == GizmoContext.sale or gizmo_context == GizmoContext.gizmo_return
      return false
    else
      raise NoMethodError
    end
  end

  def combine_cash_payments
    cashes = payments.find_all{|x| x.payment_method.name == "cash"}
    if cashes.length > 0
      cash = Payment.new
      cash.payment_method = PaymentMethod.cash
      cash.amount_cents = 0
      for i in cashes
        cash.amount_cents += i.amount_cents
        i.destroy
      end
      payments.reject!{|x|
        x.payment_method.name == "cash"
      }
      payments << cash if cash.amount_cents > 0
    end
  end

  def has_some_uneditable
    gizmo_events.collect{|x| x.editable}.select{|x| x == false}.length > 0
  end

  def hooman_class_name
    self.class.to_s.tableize.humanize.singularize.downcase
  end

  def editable_explaination
    str = ""
    if ! self.editable?
      str = "This #{self.hooman_class_name} is not editable because its associated store credit has already been spent"
    elsif self.has_some_uneditable
      str = "Some pieces of this #{self.hooman_class_name} are not editable because their associated store credit has already been spent"
    end
    return str
  end

  def html_explaination
    if !editable_explaination.blank?
      return '<pre style="background: yellow">' +
        editable_explaination +
        '</pre>'
    end
    return ""
  end

  def real_occurred_at
    self.read_attribute(:occurred_at)
  end

  def set_occurred_at_on_transaction
    self.occurred_at = DateTime.now if self.occurred_at.nil?
  end

  def occurred_at
    value = case self
           when Sale
             self.real_occurred_at
           when Donation
             self.real_occurred_at
           when GizmoReturn
             self.real_occurred_at
           when Disbursement
             self.disbursed_at
           when Recycling
             self.recycled_at
           else
             raise NoMethodError
           end
    return value || Time.now
  end

  def set_occurred_at_on_gizmo_events
    self.gizmo_events.each {|event| event.occurred_at = self.occurred_at; event.save! unless event.id.nil?} # stupid has_many relationships...
  end

  #########
  protected
  #########

  def unzero_contact_id
    if contact_type != 'named'
      self.contact_id = nil
    end
  end

  def required_contact_type
    # the contact type to actually apply to a named contact who did the txn
    # used in add_contact_types
    # overridden in each class which mixes this in (not dispersments, recycling)
  end

  def add_contact_types
    if(contact and
       (contact_type == 'named' and
        required_contact_type != nil))
      for x in [required_contact_type].flatten
        if (! contact.contact_types.include?(x))
          contact.contact_types << x
        end
      end
    end
  end
end
