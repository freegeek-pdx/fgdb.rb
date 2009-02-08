class CreateXapianJobs < ActiveRecord::Migration
  def self.up
    create_table :xapian_jobs do |t|
      t.integer :book_id

      t.timestamps
    end
  end

  def self.down
    drop_table :xapian_jobs
  end
end
