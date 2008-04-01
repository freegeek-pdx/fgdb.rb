class Donation < ActiveRecord::Base
  acts_as_userstamp

  include GizmoTransaction
  belongs_to :contact, :order => "surname, first_name"
  has_many :payments, :dependent => :destroy
  has_many :gizmo_events, :dependent => :destroy

  before_save :add_contact_types

  define_amount_methods_on("reported_required_fee")
  define_amount_methods_on("amount_invoiced")
  define_amount_methods_on("cash_donation_owed")
  define_amount_methods_on("reported_suggested_fee")

  def initialize(*args)
    super(*args)
  end

  attr_writer :contact_type #anonymous, named, or dumped

  before_save :cleanup_for_contact_type
  before_save :set_occurred_at_on_gizmo_events

  def validate
    if contact_type == 'named'
      errors.add_on_empty("contact_id")
    elsif contact_type == 'anonymous'
      errors.add_on_empty("postal_code")
    elsif contact_type != 'dumped'
      errors.add("contact_type", "should be one of 'named', 'anonymous', or 'dumped'")
    end
    gizmo_events.each do |gizmo|
       errors.add("gizmos", "must have positive quantity") unless gizmo.valid_gizmo_count?
    end
    errors.add("payments", "are too little to cover required fees") unless(invoiced? or required_paid? or contact_type == 'dumped')
    errors.add("payments", "or gizmos should include some reason to call this a donation") if
      gizmo_events.empty? and payments.empty?
    errors.add("payments", "may only have one invoice") if invoices.length > 1
  end

  def donor
    if contact_type == 'named'
      contact
    elsif contact_type == 'anonymous'
      "anonymous(#{postal_code})"
    else
      'dumped'
    end
  end

  def contact_type
    unless @contact_type
      if contact
        @contact_type = 'named'
      elsif postal_code != '' and not postal_code.nil?
        @contact_type = 'anonymous'
      elsif id
        @contact_type = 'dumped'
      else
        @contact_type = 'named'
      end
    end
    @contact_type
  end

  def required_contact_type
    ContactType.find(7)
  end

  def reported_total_cents
    reported_required_fee_cents + reported_suggested_fee_cents
  end

  def calculated_required_fee_cents
    gizmo_events.inject(0) {|total, gizmo|
      next if gizmo.mostly_empty?
      total + gizmo.required_fee_cents
    }
  end

  def calculated_suggested_fee_cents
    gizmo_events.inject(0) {|total, gizmo|
      total + gizmo.suggested_fee_cents
    }
  end

  def calculated_total_cents
    calculated_suggested_fee_cents + calculated_required_fee_cents
  end

  def cash_donation_owed_cents
    [0, (amount_invoiced_cents - reported_required_fee_cents) - cash_donation_paid_cents].max
  end

  def cash_donation_paid_cents
    [0, money_tendered_cents - required_fee_paid_cents].max
  end

  def required_fee_owed_cents
    if invoiced? and (reported_required_fee_cents > required_fee_paid_cents)
        [reported_required_fee_cents - required_fee_paid_cents, amount_invoiced_cents].min
    else
      0
    end
  end

  def required_fee_paid_cents
    [reported_required_fee_cents, money_tendered_cents].min
  end

  def required_paid?
    money_tendered_cents >= calculated_required_fee_cents
  end

  def invoiced?
    payments.detect {|payment| payment.payment_method_id == PaymentMethod.invoice.id}
  end

  def overunder_cents(only_required = false)
    if only_required
      money_tendered_cents - calculated_required_fee_cents
    else
      money_tendered_cents - calculated_total_cents
    end
  end

  #######
  private
  #######

  def cleanup_for_contact_type
    case contact_type
    when 'named'
      self.postal_code = nil
    when 'anonymous'
      self.contact_id = nil
    when 'dumped'
      self.postal_code = self.contact_id = nil
    end
  end

  def set_occurred_at_on_gizmo_events
    self.gizmo_events.each {|event| event.occurred_at = self.created_at}
  end

end
