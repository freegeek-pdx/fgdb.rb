class CreateReasonCannotLoginField < ActiveRecord::Migration
  def self.up
    add_column :users, :reason_cannot_login, :string
  end

  def self.down
    remove_column :users, :reason_cannot_login, :string
  end
end
