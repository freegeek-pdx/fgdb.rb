class PayPeriod < ActiveRecord::Base
  def PayPeriod.find_for_date(date)
    return PayPeriod.find(:first, :conditions => ['start_date <= ? AND end_date >= ?', date, date])
  end
end
