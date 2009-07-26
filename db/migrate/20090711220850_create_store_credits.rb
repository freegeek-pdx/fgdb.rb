class CreateStoreCredits < ActiveRecord::Migration
  def self.up
    create_table :store_credits do |t|
      t.integer :gizmo_return_id
      t.integer :gizmo_event_id
      t.integer :payment_id
      t.integer :amount_cents

      t.timestamps
    end
    add_foreign_key "store_credits", "gizmo_return_id", "gizmo_returns", "id", :on_delete => :cascade
    add_foreign_key "store_credits", "gizmo_event_id", "gizmo_events", "id", :on_delete => :cascade
    add_foreign_key "store_credits", "payment_id", "payments", "id", :on_delete => :set_null
  end

  def self.down
    drop_table :store_credits
  end
end
