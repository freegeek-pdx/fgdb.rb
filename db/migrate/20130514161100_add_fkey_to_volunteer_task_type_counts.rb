class AddFkeyToVolunteerTaskTypeCounts < ActiveRecord::Migration
  def self.up
    add_foreign_key :contact_volunteer_task_type_counts, :contact_id, :contacts, :id
  end

  def self.down
  end
end
