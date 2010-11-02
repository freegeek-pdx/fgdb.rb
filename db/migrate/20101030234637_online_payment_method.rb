class OnlinePaymentMethod < ActiveRecord::Migration
  def self.up
    p = PaymentMethod.new
    p.name = "online"
    p.description = "online"
    p.save!
  end

  def self.down
  end
end
