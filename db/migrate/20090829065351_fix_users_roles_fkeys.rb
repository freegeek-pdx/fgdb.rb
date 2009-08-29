class FixUsersRolesFkeys < ActiveRecord::Migration
  def self.up
    remove_foreign_key :roles_users, :roles_users_role_id_fkey
    remove_foreign_key :roles_users, :roles_users_user_id_fkey
    add_foreign_key("roles_users", [:user_id], "users", [:id], :name => "roles_users_user_id_fkey", :on_delete => :cascade)
    add_foreign_key("roles_users", [:role_id], "roles", [:id], :name => "roles_users_role_id_fkey", :on_delete => :cascade)
  end

  def self.down
  end
end
