class CreatePayPeriods < ActiveRecord::Migration
  def self.up
    create_table :pay_periods do |t|
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end

  def self.down
    drop_table :pay_periods
  end
end
