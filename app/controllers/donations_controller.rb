class DonationsController < TransactionController
  def invoices
    if params[:contact]
      @contact = Contact.find_by_id(params[:contact][:id].to_i)
    end
    if @contact
      @invoices = @contact.unresolved_donations.sort_by(&:occurred_at)
      @transaction = Donation.new(:contact => @contact)
    end
    if @contact and params[:invoices]
      begin
        @resolved_date = Date.parse(params[:donation][:invoice_resolved_at])
      rescue
        @resolved_date = Date.today
      end
      @transaction.occurred_at = @resolved_date
      _apply_line_item_data(@transaction)
      gt = GizmoType.find_by_name("invoice_resolved")
      params[:invoices].each do |k|
        d = Donation.find_by_id(k)
        @transaction.gizmo_events << GizmoEvent.new(:gizmo_type => gt, :unit_price_cents => d.invoice_amount_cents, :invoice_donation => d, :gizmo_count => 1, :gizmo_context => @gizmo_context, :covered => false)
      end
      if @transaction.calculated_under_pay < 0
        @transaction.payments << Payment.new(:amount_cents => -1 * @transaction.calculated_under_pay, :payment_method => PaymentMethod.invoice)
      end
      Thread.current['cashier'] = Thread.current['user']
      @transaction.valid? # add errors, otherwise mine below will prevent the check
      # TODO: CHECK OTHER THINGS: ..?
      for i in @transaction.gizmo_events
        @transaction.errors.add('invoices', 'are already resolved') if i.invoice_donation.resolved?
      end
      # NOTE: not valid?, as I am adding errors manually after
      if @transaction.errors.length == 0
        @transaction.save
        @show_id = @transaction.id
        @contact = nil
      end
    else
      @resolved_date = Date.today
    end
  end

  def tally_sheet
    @results = DB.exec("SELECT gizmo_types.description AS description, CASE WHEN required_fee_cents > 0 THEN required_fee_cents/100 ELSE suggested_fee_cents/100 END AS amount, covered AS covered, required_fee_cents > 0 AS required FROM gizmo_types LEFT JOIN gizmo_contexts_gizmo_types ON gizmo_types.id = gizmo_contexts_gizmo_types.gizmo_type_id WHERE gizmo_context_id = 1 AND (gizmo_types.ineffective_on IS NULL OR gizmo_types.ineffective_on > current_date) AND (gizmo_types.effective_on IS NULL OR gizmo_types.effective_on <= current_date) AND gizmo_types.name NOT IN ('invoice_resolved', 'service_fee_other', 'service_fee_education', 'service_fee_pickup', 'service_fee_tech_support') ORDER BY covered DESC, rank, gizmo_types.description;").to_a
  end

  def civicrm_sync
    _civicrm_sync
  end

  protected

  def default_condition
    "created_at"
  end
end
