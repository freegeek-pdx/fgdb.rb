class PaymentMethod < ActiveRecord::Base
  def to_s
    description
  end

  def PaymentMethod.cash
    @@cash ||= find_by_name('cash')
  end

  def PaymentMethod.check
    @@check ||= find_by_name('check')
  end

  def PaymentMethod.invoice
    @@invoice ||= find_by_name('invoice')
  end

  def PaymentMethod.coupon
    @@coupon ||= find_by_name('coupon')
  end

  def PaymentMethod.credit
    @@credit ||= find_by_name('credit')
  end

  def PaymentMethod.store_credit
    @@store_credit ||= find_by_name('store_credit')
  end

  def PaymentMethod.is_till_method?(id)
    return [cash, check].map(&:id).include?(id)
  end

  def PaymentMethod.is_money_method?(id)
    return [cash, check, credit].map(&:id).include?(id)
  end

  def PaymentMethod.is_fake_method?(id)
    return fake_money_methods.map(&:id).include?(id)
  end

  def PaymentMethod.till_methods()
    return [cash, check]
  end

  def PaymentMethod.real_non_till_methods()
    return [credit]
  end

  def PaymentMethod.fake_money_methods()
    return [invoice, coupon, store_credit]
  end

  def PaymentMethod.descriptions
    @@descriptions ||= {}
    if @@descriptions.empty?
      find(:all).each {|p_m|
        @@descriptions[p_m.id] = p_m.description
      }
    end
    @@descriptions
  end
end
