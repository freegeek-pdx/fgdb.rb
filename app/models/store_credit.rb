class StoreCredit < ActiveRecord::Base
  belongs_to :payment

  define_amount_methods_on :amount

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

  private

  def _spent_on
    return payment
  end

  def _is_spent
    return ! payment.nil?
  end
end
