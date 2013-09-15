class RemovePricingTables < ActiveRecord::Migration
  def self.up
    drop_table :pricing_bonus
    drop_table :pricing_components
    drop_table :pricing_expressions
    drop_table :pricing_types
    drop_table :pricing_values
    drop_table :pricing_values_system_pricings
  end

  def self.down
  end
end
