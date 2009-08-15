class CreateShortTills < ActiveRecord::Migration
  def self.up
    create_table "short_tills", :id => false, :force => true do |t|
      t.string  "till_type", :limit => 2
      t.date    "till_date"
      t.integer "shortage"
    end
  end

  def self.down
    drop_table "short_tills"
  end
end
