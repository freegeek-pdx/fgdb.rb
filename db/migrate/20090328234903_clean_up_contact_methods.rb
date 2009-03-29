class CleanUpContactMethods < ActiveRecord::Migration
  def self.up
    ContactMethod.connection.execute("DELETE FROM contact_methods WHERE contact_id IS NULL")
  end

  def self.down
  end
end
