module GizmoTransaction
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
    payments.map {|payment| payment.payment_method.description}.uniq.join( ' ' )
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
        required_contact_type != nil and
        (! contact.contact_types.include?(required_contact_type)))
       )
      contact.contact_types << required_contact_type
    end
  end
end
