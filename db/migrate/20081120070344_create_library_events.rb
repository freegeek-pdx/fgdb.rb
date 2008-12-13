class CreateLibraryEvents < ActiveRecord::Migration
  def self.up
    create_table :library_events do |t|
      t.integer :contact_id
      t.integer :type
      t.datetime :date
      t.integer :copy_id

      t.timestamps
    end
  end

  def self.down
    drop_table :library_events
  end
end
