class AddRealMoneyPaidToSales < ActiveRecord::Migration
  def self.up
    add_column :sales, :amount_real_money_paid_cents, :integer
    DB.exec("UPDATE sales SET amount_real_money_paid_cents = COALESCE((SELECT SUM(real_payments.amount_cents) FROM payments AS real_payments JOIN payment_methods AS real_payment_methods ON real_payments.payment_method_id = real_payment_methods.id WHERE real_payments.sale_id = sales.id AND real_payment_methods.name != 'store_credit' AND real_payment_methods.name != 'coupon'), 0);")
  end

  def self.down
  end
end
