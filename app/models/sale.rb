class Sale < ActiveRecord::Base
  acts_as_userstamp
  validates_presence_of :discount_name
  include GizmoTransaction
  belongs_to :contact
  has_many :payments, :dependent => :destroy, :autosave => :true
  belongs_to :discount_percentage
  belongs_to :discount_name
  has_many :gizmo_events, :dependent => :destroy, :autosave => :true
  has_many :gizmo_types, :through => :gizmo_events

  def gizmo_context
    GizmoContext.sale
  end

  before_save :add_contact_types
  before_save :unzero_contact_id
  before_save :add_change_line_item
  before_save :compute_fee_totals
  before_save :set_occurred_at_on_gizmo_events
  before_save :combine_cash_payments
  before_save :set_occurred_at_on_transaction
  before_save :strip_postal_code

  def self.default_discount
    Sale.new.discount_name.id
  end

  def self.default_volunteer_discount
    DiscountName.find(Default["discount_name_id_for_volunteer_discount"]).id
  end

  def self.default_discount_percentage
    Sale.new.discount_percentage.id
  end

  def self.default_volunteer_discount_percentage
    DiscountPercentage.find(Default["discount_percentage_id_for_volunteer_discount"]).id
  end

  def self.number_by_conditions(c)
    Sale.connection.execute("SELECT count(*) FROM sales WHERE #{sanitize_sql_for_conditions(c.conditions(Sale))}").to_a[0]["count"].to_i
  end

  def initialize(*args)
    @contact_type = 'anonymous'
    super(*args)
  end

  def discount_name_name
    ""
  end

  def discount_name_name=(text)
    if text != ""
      self.discount_name = DiscountName.find_by_description(text)
      if ! self.discount_name
        self.discount_name = DiscountName.new
        self.discount_name.available = false # default to not available
        self.discount_name.description = text
      end
    end
  end

  def storecredit_alert_text
    self.storecredits.select{|x| !x.spent?}.map{|credit|
          "Store Credit Hash ##{StoreChecksum.new_from_result(credit.id).checksum}\n\nAmount: $#{credit.amount}\nExpires: #{credit.valid_until.strftime("%B %d, %Y")}"
        }.join("\n\n\n")
  end

  # Quick Testing: ./script/runner 'class F; include RawReceiptHelper; def session; {}; end; end; puts F.new.generate_raw_receipt{|lim| Sale.last.text_receipt_lines(lim)}'
  def text_receipt_lines(fulllimit)
    store_credit_gizmo_events = self.gizmo_events_actual.select{|x| x.gizmo_type.name == "store_credit"}
    other_gizmo_events = self.gizmo_events_actual - store_credit_gizmo_events
    gizmo_lines =  []
    other_gizmo_events.each{|event|
      iszero = event.percent_discount == 0
      gizmo_lines << [ 'left', event.attry_description( :upcase => true, :ignore => ['unit_price'] ) ]
      gizmo_lines << ['right', event.gizmo_count.to_s + ' @', event.unit_price.to_s, iszero ? '' : event.total_price_cents.to_dollars.to_s, iszero ? '' : ('less ' + event.percent_discount.to_s + "%"), event.discounted_price.to_dollars.to_s]
    }
    store_credit_gizmo_events_total_cents = store_credit_gizmo_events.inject(0){|t,x| t+=x.total_price_cents} 
    gizmo_lines << []
    payment_lines = []
    unless self.calculated_discount_cents == 0
      payment_lines << ['right', "Subtotal:", "#{(self.calculated_subtotal_cents - store_credit_gizmo_events_total_cents).to_dollars}"]
      payment_lines << ['right', "Discounted:", "#{self.calculated_discount_cents.to_dollars}"]
    end
    payment_lines << ['right', "Total:", "#{(self.calculated_total_cents - store_credit_gizmo_events_total_cents).to_dollars}"]
    seen_cash = false
    seen_sc = false
    cash_back = (defined?(@cash_back) and @cash_back > 0) ? @cash_back : 0
    self.payments_actual.each{|payment|
      amount = payment.amount_cents
      if payment.payment_method.name == "store_credit" and !seen_sc
        amount -= store_credit_gizmo_events_total_cents
        seen_sc = true
      end
      if payment.payment_method.name == "cash" && cash_back > 0 && !seen_cash
        seen_cash = true
        amount += cash_back
      end
      payment_lines << ['right', payment.payment_method.description + ":", amount.to_dollars]
    }
    if cash_back > 0
      payment_lines << ['right', "change due:", "#{cash_back.to_dollars}"]
    end
    if store_credit_gizmo_events_total_cents > 0 and !seen_sc
      payment_lines << ['right', "store credit:", (-1 * store_credit_gizmo_events_total_cents).to_dollars]
    end
    if self.calculated_total_cents > self.money_tendered_cents && !self.invoice_resolved?
      payment_lines << ['right',     "Due by #{self.created_at.to_date + 30 }:", (self.calculated_total_cents - self.money_tendered_cents).to_dollars]
    end

    head_lines =   ["+---------------------------+",
    "| Free Geek Thrift Store    |",
  "| 1731 SE 10th Ave. PDX     |",
  "| 10-6 Mon. through Sat.    |",
  "| freegeek.org/thrift-store |",
   "+---------------------------+"].map{|x| ['center', x]}
    head_lines = head_lines + [[],
                               ['two', " #{self.occurred_at.strftime("%H:%M %p %m/%d/%y").downcase}", "sale: #{self.id}"],
                               ['two', " cashier: #{User.find_by_id(self.read_attribute(:cashier_created_by)).contact_id}", "cust: #{self.contact_id || "anonymous"}"]]
    percent = self.discount_percentage.percentage
    if percent != 0
      head_lines << []
      head_lines << ['center', "### #{sprintf('%d', percent)}% #{self.discount_name.description.upcase} DISCOUNT APPLIED ###"]
    end
    head_lines << []
    footer_lines = [[]] + self.display_return_policies.map{|x| ['left', x.full_text]}
    if self.comments and self.comments.length >= 1
      footer_lines = [[], ['left', 'Comments: ' + self.comments]] + footer_lines
    end
    thanks = []
    if fulllimit == 44
thanks = [
"      _                    _            ",
"     | |                  | |        |||",
" _|_ | |     __,   _  _   | |   ,    |||",
"  |  |/ \\   /  |  / |/ |  |/_) / \\_  |||",
"  |_/|   |_/\\_/|_/  |  |_/| \\_/ \\/   ooo",
""].map{|t| ['standard', t]}
    end
    thanks << ['left', "Follow us on Twitter for New Items, Sales and Coupons:"]
    thanks << ['right', "twitter.com/fgthriftstore"]
    thanks << ['left', "Like us on FaceBook:"]
    thanks << ['right', "facebook.com/freegeekmothership"]
    final = head_lines + gizmo_lines + payment_lines + footer_lines + thanks
    final
  end

  def display_return_policies
    self.gizmo_events_actual.map(&:gizmo_type).map{|x| x.my_return_policy_id}.select{|x| !x.nil?}.uniq.sort.map{|x| ReturnPolicy.find_by_id(x)}
  end

  attr_accessor :contact_type  #anonymous or named

  define_amount_methods_on("reported_discount_amount")
  define_amount_methods_on("reported_amount_due")

  def storecredits
    self.gizmo_events_actual.map{|x| x.store_credits}.flatten
  end

  def validate
    validate_inventory_modifications
    unless is_adjustment?
    if contact_type == 'named'
      errors.add_on_empty("contact_id")
      if contact_id.to_i == 0 or !Contact.exists?(contact_id)
        errors.add("contact_id", "does not refer to any single, unique contact")
      end
    else
      nil
    end
    end
    errors.add("payments", "are too little to cover the cost") unless invoiced? or total_paid?
    #errors.add("payments", "are too much") if overpaid?
    errors.add("payments", "may only have one invoice") if invoices.length > 1
    errors.add("gizmos", "should include something") if gizmo_events_actual.empty?
    errors.add("payments", "use the same store credit multiple times") if storecredits_repeat

    payments_actual.each{|x|
      x.errors.each{|y, z|
        errors.add("payments", z)
      }
    }
    gizmo_events_actual.each{|x|
      x.errors.each{|y, z|
        errors.add("gizmos", z)
      }
    }

    storecred_received = self.storecredits.inject(0){|t,x| t += x.amount_cents}
    storecred_spent = amount_from_some_payments(store_credits_spent)
    oldstorecredit = 0
    if self.id
      oldstorecredit = self.class.find_by_id(self.id).storecredits.inject(0){|t,x| t += x.amount_cents}
    end
    storecredit_priv_check if storecred_received > storecred_spent and storecred_received > oldstorecredit
  end

  def storecredits_repeat
    sc = self.payments_actual.select{|x| x.payment_method == PaymentMethod.store_credit}.map{|x| x.store_credit_id}
    sc.length != sc.uniq.length
  end

  class << self
    def default_sort_sql
      "sales.occurred_at DESC"
    end

    def totals(conditions)
      bulk_id = ContactType.bulk_buyer.id
      connection.execute(
                         "SELECT payments.payment_method_id,
                sale_types.description AS sale_type,
                sum(payments.amount_cents) as amount,
                count(*),
                min(sales.id),
                max(sales.id)
         FROM sales
         JOIN payments ON payments.sale_id = sales.id
         JOIN sale_types ON sale_types.id = sale_type_id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         GROUP BY 1, 2"
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
    gizmo_events_actual.inject(0) {|tot,gizmo|
      gizmo.sale = self
      tot + gizmo.discounted_price
    }
  end

  def calculated_discount_cents
    calculated_subtotal_cents - calculated_total_cents
  end

  def store_credits_spent
    payments_actual.select{|x| x.is_storecredit?}
  end

  def other_spent # not store credit
    payments_actual.select{|x| !x.is_storecredit?}
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
    return [0, 0]
  end

  def add_change_line_item()
    if self.payments_actual.length == 1 and self.payments_actual.first.payment_method.id == PaymentMethod.credit.id
      self.payments_actual.first.amount_cents = self.calculated_total_cents
      self.payments_actual.first.save
      return
    end
    storecredit_back, cash_back = _figure_it_all_out
    if storecredit_back > 0
      # wow, if only I had a working test suite...testing this through the UI is a PITA!!!!
      # mebbe we should fix that.
      gizmo_events.build({:unit_price_cents => storecredit_back,
                            :gizmo_count => 1,
                            :gizmo_type => GizmoType.find_by_name("store_credit"),
                           :covered => false,
                                       :gizmo_context => self.gizmo_context})
# <Ryan52> so it should just recalculate the expire date always? <store> yeah, that's it
#                            :expire_date => store_credits_spent.map{|x| x.store_credit.expire_date}.uniq.select{|x| !x.nil?}.sort.last}) # WTF? something sets gizmo_context on *everything* else. why doesn't it set it on this one? hm...I can't find that code anyway.
    end
    if cash_back > 0
      payments.build({:amount_cents => -cash_back,
                                :payment_method => PaymentMethod.cash})
    end
    @cash_back = cash_back
  end
end
