class AddVolunteerInternTitle < ActiveRecord::Migration
  def self.up
    add_column :contacts, :volunteer_intern_title, :string
  end

  def self.down
    remove_column :contacts, :volunteer_intern_title
  end
end
