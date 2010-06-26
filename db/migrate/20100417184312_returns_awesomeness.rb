class ReturnsAwesomeness < ActiveRecord::Migration
  def self.up
    add_column :gizmo_events, :reason, :string
    add_column :gizmo_events, :tester, :string
    add_column :gizmo_events, :return_sale_id, :integer
    remove_column :gizmo_returns, :sale_id
    remove_column :gizmo_returns, :disbursement_id
  end

  def self.down
    remove_column :gizmo_events, :reason
    remove_column :gizmo_events, :tester
    remove_column :gizmo_events, :return_sale_id
    add_column :gizmo_returns, :sale_id, :integer
    add_column :gizmo_returns, :disbursement_id, :integer
  end
end
