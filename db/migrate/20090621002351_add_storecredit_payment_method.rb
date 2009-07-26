class AddStorecreditPaymentMethod < ActiveRecord::Migration
  def self.up
    DisbursementType.new({:name => "replacement", :description => "Replacement"}).save!
  end

  def self.down
    DisbursementType.find_by_name("replacement").destroy
  end
end
