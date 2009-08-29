class AddCanLoginFieldToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :can_login, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :users, :can_login
  end
end
