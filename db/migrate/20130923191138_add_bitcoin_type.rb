class AddBitcoinType < ActiveRecord::Migration
  def self.up
    pm = PaymentMethod.new
    pm.name = "bitcoin"
    pm.description = "bitcoin"
    pm.save!
  end

  def self.down
  end
end
