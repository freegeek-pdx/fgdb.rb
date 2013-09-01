class StoreCredit < ActiveRecord::Base
  belongs_to :payment
  belongs_to :gizmo_event
  belongs_to :gizmo_return

  define_amount_methods_on :amount

  def self.refunds(conditions)
    self.connection.execute("SELECT COALESCE(SUM(amount_cents),0) AS amt_cents, COALESCE(COUNT(amount_cents),0) AS count FROM store_credits WHERE #{sanitize_sql_for_conditions(conditions).gsub(/sales/, 'store_credits').gsub(/occurred_at/, 'created_at')};").to_a.first
  end

  def all_instances
    res = [all_previous, self, all_next].flatten.sort_by(&:created_at).uniq
  end

  def all_previous
    a = self.previous
    a.map{|x| x.previous} + a
  end

  def previous
    # if it came from remainder of a sale
    if self.gizmo_event
      self.gizmo_event.sale.payments.select{|x| !!x.store_credit_id}.map{|x| x.store_credit}
    else
      # if it came from a gizmo return, just in case an old credit was integrated
      self.gizmo_return.gizmo_events.map{|x| x.return_store_credit_id}.select{|x| !x.nil?}.map{|x| StoreCredit.find_by_id(x)}
    end
  end

  def all_next
    a = self.next
    a + a.map{|x| x.next}
  end

  def next
    # if it was spent on a sale
    if self.payment_id
      self.payment.sale.gizmo_events.map{|x| x.store_credits}.flatten
    else
      # if it was added to a new return
      GizmoEvent.find_all_by_return_store_credit_id(self.id).map{|x| x.gizmo_return}
    end
  end

  def spent?
    @spent ||= _is_spent
  end

  def spent_on
    @spent_on ||= _spent_on
  end

  def cache_shit
    spent_on
    spent?
    nil
  end

  def still_valid?(date = Date.today)
    date <= self.valid_until
  end

  def valid_until
    expire_date
  end

  def store_credit_hash
    StoreChecksum.new_from_result(self.id).checksum
  end

  def self.expire_after_value
    eval(Default["storecredit_expire_after"])
  end

#  private  ## HELPME, this breaks it.

  def _spent_on
    return payment
  end

  def my_return
    self.id ? GizmoEvent.find_by_return_store_credit_id(self.id) : nil
  end

  def is_returned
    self.id && !! self.my_return
  end

  def _is_spent
    return !(payment.nil?) || is_returned
  end
end
