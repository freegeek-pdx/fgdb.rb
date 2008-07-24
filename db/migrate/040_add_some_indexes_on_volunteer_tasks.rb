class AddSomeIndexesOnVolunteerTasks < ActiveRecord::Migration
  def self.up
    add_index :volunteer_tasks, :date_performed
    add_index :volunteer_tasks, :community_service_type_id
    add_index :volunteer_tasks, :volunteer_task_type_id
    add_index :volunteer_tasks, :duration
  end

  def self.down
  end
end
