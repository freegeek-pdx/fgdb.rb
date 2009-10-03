class AddSomeBlahForDiscountDefaults < ActiveRecord::Migration
  def self.up
    Default['hours_for_discount'] = 4.0
    Default['days_for_discount'] = 90
  end

  def self.down
  end
end
