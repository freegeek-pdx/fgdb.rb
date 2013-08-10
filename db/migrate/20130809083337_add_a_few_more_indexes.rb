class AddAFewMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index :assignments, :attendance_type_id
    add_index :volunteer_events, :date
    add_index :volunteer_shifts, :roster_id
  end

  def self.down
  end
end
