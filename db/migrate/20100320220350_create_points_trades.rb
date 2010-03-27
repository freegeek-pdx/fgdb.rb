class CreatePointsTrades < ActiveRecord::Migration
  def self.up
    create_table :points_trades do |t|
      t.integer :from_contact_id
      t.integer :to_contact_id
      t.decimal :points
      t.integer :created_by
      t.integer :updated_by
      t.integer :cashier_created_by
      t.integer :cashier_updated_by

      t.timestamps
    end
  end

  def self.down
    drop_table :points_trades
  end
end
