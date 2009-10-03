class CleanUpDiscountSchedulesGizmoTypes < ActiveRecord::Migration
  def self.up
    DB.sql("DELETE FROM discount_schedules_gizmo_types WHERE multiplier IS NULL;")
  end

  def self.down
  end
end
