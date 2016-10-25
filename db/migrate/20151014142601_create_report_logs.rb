class CreateReportLogs < ActiveRecord::Migration
  def self.up
    create_table :report_logs do |t|
      t.string :report_name
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :report_logs
  end
end
