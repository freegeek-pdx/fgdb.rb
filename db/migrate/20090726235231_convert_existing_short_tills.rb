class ConvertExistingShortTills < ActiveRecord::Migration
  def self.up
    DB.execute("INSERT INTO till_adjustments(till_type_id, till_date, adjustment_cents) SELECT till_types.id, till_date, shortage FROM short_tills, till_types WHERE till_types.name = short_tills.till_type;")
    drop_table "short_tills"
  end

  def self.down
  end
end
