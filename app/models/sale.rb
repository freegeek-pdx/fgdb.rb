class Sale < ActiveRecord::Base
  acts_as_userstamp

  include GizmoTransaction
  belongs_to :contact
  has_many :payments, :dependent => :destroy
  belongs_to :discount_schedule
  has_many :gizmo_events, :dependent => :destroy
  has_many :gizmo_types, :through => :gizmo_events
  has_many :gizmo_returns

  def gizmo_context
    GizmoContext.sale
  end

  before_save :add_contact_types
  before_save :unzero_contact_id
  before_save :compute_fee_totals
  before_save :add_change_line_item
  before_save :set_occurred_at_on_gizmo_events
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
    errors.add("payments", "use the same store credit multiple times") if storecredits_repeat
    payments.each{|x|
      x.errors.each{|y, z|
        errors.add("payments", z)
      }
    }
    gizmo_events.each{|x|
      x.errors.each{|y, z|
        errors.add("gizmos", z)
      }
    }
  end

  def storecredits_repeat
    sc = self.payments.select{|x| x.payment_method == PaymentMethod.store_credit}.map{|x| x.store_credit_id}
    sc.length != sc.uniq.length
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

  def buyer
    contact ?
    contact.display_name :
      "anonymous(#{postal_code})"
  end

  def contact_type
    @contact_type ||= contact ? 'named' : 'anonymous'
  end

  def required_contact_type
    ContactType.find_by_name('buyer')
  end

  def calculated_total_cents
    if discount_schedule
      gizmo_events.inject(0) {|tot,gizmo|
        gizmo.sale = self
        tot + gizmo.discounted_price(discount_schedule)
      }
    else
      calculated_subtotal_cents
    end
  end

  def calculated_discount_cents
    calculated_subtotal_cents - calculated_total_cents
  end

  def store_credits_spent
    payments.select{|x| x.is_storecredit?}
  end

  def other_spent # not store credit
    payments.select{|x| !x.is_storecredit?}
  end

  #########
  protected
  #########

  def compute_fee_totals
    self.reported_amount_due_cents = self.calculated_total_cents
    self.reported_discount_amount_cents = self.calculated_discount_cents
  end

  # WOAH! commented code.
  def _figure_it_all_out
    amount_i_owe = calculated_total_cents
    money_given = amount_from_some_payments(other_spent)
    storecredit_given = amount_from_some_payments(store_credits_spent)

    amount_i_owe -= storecredit_given
    if amount_i_owe < 0 # more store credit than the amount to be spent
      storecredit_to_give_back = -1 * amount_i_owe
      cash_to_give_back = money_given
      return [storecredit_to_give_back, cash_to_give_back]
    end

    # ok, either the store credit was just right, or we owe more money

    amount_i_owe -= money_given
    if amount_i_owe < 0 # more money was given than the amount to be spent
      storecredit_to_give_back = 0
      cash_to_give_back = -1 * amount_i_owe
      return [storecredit_to_give_back, cash_to_give_back]
    end

    if amount_i_owe == 0
      return [0, 0]
    end

    # amount_i_owe > 0 ... still need to pay more.
    raise NoMethodError # Ryan broke something..I guess.
  end

  def add_change_line_item()
    storecredit_back, cash_back = _figure_it_all_out
    if storecredit_back > 0
      # wow, if only I had a working test suite...testing this through the UI is a PITA!!!!
      # mebbe we should fix that.
      gizmo_events << GizmoEvent.new({:unit_price_cents => storecredit_back,
                            :gizmo_count => 1,
                            :gizmo_type => GizmoType.find_by_name("store_credit"),
                            :gizmo_context => self.gizmo_context}) # WTF? something sets gizmo_context on *everything* else. why doesn't it set it on this one? hm...I can't find that code anyway.
    end
    if cash_back > 0
      payments << Payment.new({:amount_cents => -cash_back,
                                :payment_method => PaymentMethod.cash})
    end
  end
end
