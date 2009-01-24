class Donation < ActiveRecord::Base
  acts_as_userstamp

  include GizmoTransaction
  belongs_to :contact
  has_many :payments, :dependent => :destroy
  has_many :gizmo_events, :dependent => :destroy
  has_many :gizmo_types, :through => :gizmo_events

  def gizmo_context
    GizmoContext.donation
  end

  define_amount_methods_on("reported_required_fee")
  define_amount_methods_on("amount_invoiced")
  define_amount_methods_on("cash_donation_owed")
  define_amount_methods_on("reported_suggested_fee")

  attr_writer :contact_type #anonymous, named, or dumped

  before_save :add_contact_types
  before_save :cleanup_for_contact_type
  before_save :unzero_contact_id
  before_save :add_dead_beat_discount
  before_save :set_occurred_at_on_gizmo_events
  before_save :compute_fee_totals
  before_save :combine_cash_payments

  def self.number_by_conditions(c)
    Donation.connection.execute("SELECT count(*) FROM donations WHERE #{sanitize_sql_for_conditions(c.conditions(Donation))}").to_a[0]["count"].to_i
  end

  def validate
    if contact_type == 'named'
      errors.add_on_empty("contact_id")
      if contact_id.to_i == 0 or !Contact.exists?(contact_id)
        errors.add("contact_id", "does not refer to any single, unique contact")
      end
    elsif contact_type == 'anonymous'
      errors.add_on_empty("postal_code")
    elsif contact_type != 'dumped'
      errors.add("contact_type", "should be one of 'named', 'anonymous', or 'dumped'")
    end

    gizmo_events.each do |gizmo|
      errors.add("gizmos", "must have positive quantity") unless gizmo.valid_gizmo_count?
    end

    #errors.add("payments", "are too little to cover required fees") unless(invoiced? or required_paid? or contact_type == 'dumped')

    errors.add("payments", "or gizmos should include some reason to call this a donation") if
      gizmo_events.empty? and payments.empty?

    errors.add("payments", "may only have one invoice") if invoices.length > 1

    covered_error_checking
  end

  def covered_error_checking
    if Default["coveredness_enabled"] != "1"
      return
    end
    covered = Default["fully_covered_contact_covered_gizmo"].to_i
    uncovered = Default["unfully_covered_contact_covered_gizmo"].to_i
    num_choosen = self.gizmo_events.select{|x| x.covered}.collect{|x| x.gizmo_count}.inject(0){|x,y| x+y}
    type = ""
    if contact_type != 'named' || contact.nil?
      type = "anon"
    else # named contact
      case self.contact.fully_covered_
      when "nil": type = "unknown"
      when "yes": type = "covered"
      when "no": type = "uncovered"
      end
    end
    if type == "anon" || type == "unknown"
      if !unknown_okay(uncovered, covered, num_choosen)
        errors.add("contact_type", "must be named for donations of over #{thing(uncovered, covered)} covered items") if type == "anon"
        errors.add("contact", "must have fully_covered set for donations of over #{thing(uncovered, covered)} covered items") if type == "unknown"
      end
    end
    errors.add("gizmo_events", "may only have #{covered} covered items for contacts who are fully covered") if type == "covered" && !okay(covered, num_choosen)
    errors.add("gizmo_events", "may only have #{uncovered} covered items for contacts who are not fully covered") if type == "uncovered" && !okay(uncovered, num_choosen)
  end

  def thing(one,two)
    return nil if one == two
    return two if one == -1
    return one if two == -1
    return [one,two].min
  end
  def doesitmatter(first, second, current)
    return false if thing(first, second).nil?
    return true if current > thing(first, second)
    return false
  end
  def unknown_okay(first,second,current)
    !doesitmatter(first,second,current)
  end
  def okay(num_allowed, choosen)
    return true if num_allowed == -1
    return false if choosen > num_allowed
    return true
  end

  class << self
    def default_sort_sql
      "donations.created_at DESC"
    end

    def totals(conditions)
      total_data = {}
      methods = PaymentMethod.find(:all)
      methods.each {|method|
        total_data[method.id] = {'amount' => 0, 'required' => 0, 'suggested' => 0, 'count' => 0, 'min' => 1<<64, 'max' => 0}
      }
      self.connection.execute(
                              "SELECT payments.payment_method_id,
                sum(payments.amount_cents) as amount,
                sum(donations.reported_required_fee_cents) as required,
                sum(donations.reported_suggested_fee_cents) as suggested,
                count(*),
                min(donations.id),
                max(donations.id)
         FROM donations
         JOIN payments ON payments.donation_id = donations.id
         WHERE #{sanitize_sql_for_conditions(conditions)}
         AND (SELECT count(*) FROM payments WHERE payments.donation_id = donations.id) = 1
         GROUP BY payments.payment_method_id"
                              ).each {|summation|
        d = {}
        summation.each{|k,v|d[k] = v.to_i}
        total_data[summation['payment_method_id'].to_i] = d
      }
      Donation.paid_by_multiple_payments(conditions).each {|donation|
        required_to_be_paid = donation.reported_required_fee_cents
        donation.payments.sort_by(&:payment_method_id).each {|payment|
          #total paid
          total_data[payment.payment_method_id]['count'] += 1
          total_data[payment.payment_method_id]['amount'] += payment.amount_cents
          if required_to_be_paid > 0
            if required_to_be_paid > payment.amount_cents
              total_data[payment.payment_method_id]['required'] += payment.amount_cents
            else
              total_data[payment.payment_method_id]['required'] += required_to_be_paid
              total_data[payment.payment_method_id]['suggested'] += (payment.amount_cents - required_to_be_paid)
            end
            required_to_be_paid -= payment.amount_cents
          else
            total_data[payment.payment_method_id]['suggested'] += payment.amount_cents
          end

          total_data[payment.payment_method_id]['min'] = [total_data[payment.payment_method_id]['min'],
                                                          donation.id].min
          total_data[payment.payment_method_id]['max'] = [total_data[payment.payment_method_id]['max'],
                                                          donation.id].max
        }
      }
      return total_data.map {|method_id,sums|
        {'payment_method_id' => method_id}.merge(sums)
      }
    end

    def paid_by_multiple_payments(conditions)
      conditions[0] += " AND (SELECT count(*) FROM payments WHERE payments.donation_id = donations.id) > 1 "
      self.find(:all, :conditions => conditions, :include => [:payments])
    end
  end

  def donor
    if contact_type == 'named'
      contact.display_name
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

  def occurred_at
    created_at
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

  def overunder_cents(only_required = false)
    if only_required
      money_tendered_cents - calculated_required_fee_cents
    else
      money_tendered_cents - calculated_total_cents
    end
  end

  #########
  protected
  #########

  def compute_fee_totals
    self.reported_required_fee_cents = self.calculated_required_fee_cents
    self.reported_suggested_fee_cents = self.calculated_suggested_fee_cents
  end

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
    if self.created_at == nil
      self.created_at = Time.now
    end
    self.gizmo_events.each {|event| event.occurred_at = self.created_at; event.save!}
  end

  def add_dead_beat_discount
    under_pay = (money_tendered_cents + amount_invoiced_cents) - calculated_required_fee_cents
    if under_pay < 0:
        gizmo_events << GizmoEvent.new({:unit_price_cents => under_pay,
                                         :gizmo_count => 1,
                                         :gizmo_type => GizmoType.fee_discount,
                                         :gizmo_context => GizmoContext.donation,
                                         :covered => false})
    end
  end
end
