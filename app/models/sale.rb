class Sale < ActiveRecord::Base
  acts_as_userstamp

  include GizmoTransaction
  belongs_to :contact
  has_many :payments, :dependent => :destroy
  belongs_to :discount_schedule
  has_many :gizmo_events, :dependent => :destroy
  has_many :gizmo_types, :through => :gizmo_events

  def gizmo_context
    GizmoContext.sale
  end

  before_save :add_contact_types
  before_save :unzero_contact_id
  before_save :set_occurred_at_on_gizmo_events
  before_save :compute_fee_totals
  before_save :add_change_line_item
  before_save :combine_cash_payments

  def initialize(*args)
    @contact_type = 'named'
    super(*args)
  end

  attr_accessor :contact_type  #anonymous or named

  define_amount_methods_on("reported_discount_amount")
  define_amount_methods_on("reported_amount_due")

  def validate
    if contact_type == 'named'
      errors.add_on_empty("contact_id")
      if contact_id.to_i == 0 or !Contact.exists?(contact_id)
        errors.add("contact_id", "does not refer to any single, unique contact")
      end
    else
      errors.add_on_empty("postal_code")
    end
    errors.add("payments", "are too little to cover the cost") unless invoiced? or total_paid?
    #errors.add("payments", "are too much") if overpaid?
    errors.add("payments", "may only have one invoice") if invoices.length > 1
    errors.add("gizmos", "should include something") if gizmo_events.empty?
  end

  class << self
    def default_sort_sql
      "sales.created_at DESC"
    end

    def totals(conditions)
      connection.execute(
                         "SELECT payments.payment_method_id,
                sales.discount_schedule_id,
                sum(payments.amount_cents) as amount,
                count(*),
                min(sales.id),
                max(sales.id)
         FROM sales
         JOIN payments ON payments.sale_id = sales.id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP BY payments.payment_method_id, sales.discount_schedule_id"
                         )
    end
  end

  def occurred_at
    created_at
  end

  def buyer
    contact ?
    contact.display_name :
      "anonymous(#{postal_code})"
  end

  def contact_type
    @contact_type ||= contact ? 'named' : 'anonymous'
  end

  def required_contact_type
    ContactType.find(14)
  end

  def calculated_total_cents
    if discount_schedule
      gizmo_events.inject(0) {|tot,gizmo|
        tot + gizmo.discounted_price(discount_schedule)
      }
    else
      calculated_subtotal_cents
    end
  end

  def calculated_subtotal_cents
    gizmo_events.inject(0) {|tot,gizmo|
      tot + gizmo.total_price_cents
    }
  end

  def calculated_discount_cents
    calculated_subtotal_cents - calculated_total_cents
  end

  #########
  protected
  #########

  def compute_fee_totals
    self.reported_amount_due_cents = self.calculated_total_cents
    self.reported_discount_amount_cents = self.calculated_discount_cents
  end

  def set_occurred_at_on_gizmo_events
    if self.created_at == nil
      self.created_at = Time.now
    end
    self.gizmo_events.each {|event| event.occurred_at = self.created_at; event.save!}
  end

  def add_change_line_item()
    change_due = money_tendered_cents - calculated_total_cents
    if change_due > 0
      payments << Payment.new({:amount_cents => -change_due,
                                :payment_method => PaymentMethod.cash})
    end
  end
end
