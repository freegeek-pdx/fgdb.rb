class CreateTillAdjustments < ActiveRecord::Migration
  def self.up
    create_table :till_adjustments do |t|
      t.integer :till_type_id
      t.date :till_date
      t.integer :adjustment_cents

      t.timestamps
    end
  end

  def self.down
    drop_table :till_adjustments
  end
end
