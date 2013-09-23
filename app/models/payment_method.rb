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

  def PaymentMethod.written_off_invoice
    @@written_off_invoice ||= find_by_name('written_off_invoice')
  end

  def PaymentMethod.coupon
    @@coupon ||= find_by_name('coupon')
  end

  def PaymentMethod.credit
    @@credit ||= find_by_name('credit')
  end

  def PaymentMethod.bitcoin
    @@bitcoin ||= find_by_name('bitcoin')
  end

  def PaymentMethod.store_credit
    @@store_credit ||= find_by_name('store_credit')
  end

  def PaymentMethod.online
    @@online ||= find_by_name('online')
  end

  def PaymentMethod.is_till_method?(id)
    return self.till_methods.map(&:id).include?(id)
  end

  def PaymentMethod.is_money_method?(id)
    return (till_methods + register_non_till_methods).map(&:id).include?(id)
  end

  def PaymentMethod.is_real_method?(id)
    return (till_methods + register_non_till_methods + real_non_register_methods).map(&:id).include?(id)
  end

  def PaymentMethod.is_fake_method?(id)
    return fake_money_methods.map(&:id).include?(id)
  end

  # the next three functions should be metadata in the db #

  def PaymentMethod.till_methods()
    return [cash, check]
  end

  def PaymentMethod.register_non_till_methods()
    return [credit, bitcoin]
  end

  def PaymentMethod.real_non_register_methods()
    return [invoice, online]
  end

  def PaymentMethod.non_register_methods()
    return [written_off_invoice, coupon, store_credit]
  end

  def PaymentMethod.descriptions
    @@descriptions ||= {}
    if @@descriptions.empty?
      find(:all).each {|p_m|
        @@descriptions[p_m.id] = p_m.name == "written_off_invoice" ? "invoice" : p_m.description
      }
    end
    @@descriptions
  end
end
