class AddExpireDateToStoreCredits < ActiveRecord::Migration
  def self.up
    add_column :store_credits, :expire_date, :date
  end

  def self.down
    remove_column :store_credits, :expire_date
  end
end
