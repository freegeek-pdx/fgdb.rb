class CreateStorePricings < ActiveRecord::Migration
  def self.up
    create_table :store_pricings do |t|
      t.integer :gizmo_type_id
      t.integer :unit_price_cents
      t.integer :system_id
      t.string :description

      t.timestamps
    end

    add_column :gizmo_events, :store_pricing_id, :integer
    add_foreign_key :gizmo_events, :store_pricing_id, :store_pricings, :id, :on_delete => :set_null
    add_foreign_key :store_pricings, :system_id, :systems, :id, :on_delete => :cascade
    add_foreign_key :store_pricings, :gizmo_type_id, :gizmo_types, :id, :on_delete => :restrict

    drop_table :system_pricings
  end

  def self.down
    drop_table :store_pricings
    remove_column :gizmo_events, :store_pricing_id
  end
end
