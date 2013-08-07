class AddIndexesForVolskedjing < ActiveRecord::Migration
  def self.up
    add_index :resources_volunteer_events, :volunteer_event_id
    add_index :assignments, :volunteer_shift_id
    add_index :volunteer_shifts, :volunteer_event_id
    add_index :contact_volunteer_task_type_counts, :contact_id
    add_index :contact_volunteer_task_type_counts, :volunteer_task_type_id, :name => "contact_volunteer_task_type_counts_vtask_id_fkey"
    add_index :rosters_skeds, :sked_id
    add_index :rosters_skeds, :roster_id
  end

  def self.down
  end
end
