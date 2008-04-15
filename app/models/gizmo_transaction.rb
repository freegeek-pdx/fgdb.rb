module GizmoTransaction
  def gizmos
    gizmo_events.map {|ge| ge.display_name}.join(', ')
  end

  def payment
    payments.join( ", " )
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
    real_payments.inject(0) {|total,payment| total + payment.amount_cents}
  end

  def amount_invoiced_cents
    invoices.inject(0) {|total,payment| total + payment.amount_cents}
  end

  def invoiced?
    payments.detect {|payment| payment.payment_method_id == PaymentMethod.invoice.id}
  end

  def total_paid?
    money_tendered_cents >= calculated_total_cents
  end

  def overpaid?
    calculated_total_cents < money_tendered_cents
  end

  def contact_information
    if contact
     contact.display_name_address
    elsif postal_code
      ["Anonymous (#{postal_code})"]
    else
      ["Dumped"]
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
    unless((contact_type != 'named' or
           required_contact_type == nil or
           (contact and contact.contact_types.include?(required_contact_type))) and
           contact)
      contact.contact_types << required_contact_type
    end
  end
end
