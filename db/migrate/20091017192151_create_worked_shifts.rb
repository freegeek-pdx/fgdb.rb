class CreateWorkedShifts < ActiveRecord::Migration
  def self.up
    create_table :worked_shifts do |t|
      t.integer :worker_id
      t.integer :job_id
      t.date :date_performed
      t.decimal :duration

      t.timestamps
    end
  end

  def self.down
    drop_table :worked_shifts
  end
end
