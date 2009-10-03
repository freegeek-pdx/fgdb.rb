class EffectiveIneffectiveDatesOnGizmoTypes < ActiveRecord::Migration
  def self.up
   add_column "gizmo_types", "effective_on", :datetime, :default => 'now()'
   add_column "gizmo_types", "ineffective_on", :datetime
  end

  def self.down
    remove_column "gizmo_types", "effective_on"
    remove_column "gizmo_types", "ineffective_on"
  end
end
