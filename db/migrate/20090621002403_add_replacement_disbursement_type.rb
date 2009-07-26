class AddReplacementDisbursementType < ActiveRecord::Migration
  def self.up
    PaymentMethod.new({:description => "store credit", :name => "store_credit"}).save!
  end

  def self.down
    PaymentMethod.find_by_name("store_credit").destroy
  end
end
