class ForeignKeyForReturnSaleId < ActiveRecord::Migration
  def self.up
    add_foreign_key "gizmo_events", ["return_sale_id"], "sales", ["id"], :on_delete => :restrict, :name => "gizmo_events_return_sale_id_fk"
  end

  def self.down
    remove_foreign_key "gizmo_events", "gizmo_events_return_sale_id_fk"
  end
end
