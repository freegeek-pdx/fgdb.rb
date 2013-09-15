class AddPaymentMethodIdToReturens < ActiveRecord::Migration
  def self.up
    add_column :gizmo_returns, :payment_method_id, :integer
    add_foreign_key :gizmo_returns, :payment_method_id, :payment_methods, :id, :on_delete => :restrict
  end

  def self.down
  end
end
