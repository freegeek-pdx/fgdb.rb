class EffectiveIneffectiveOnVolunteerTaskTypes < ActiveRecord::Migration
  def self.up
   add_column "volunteer_task_types", "effective_on", :datetime, :default => 'now()'
   add_column "volunteer_task_types", "ineffective_on", :datetime
  end

  def self.down
    remove_column "volunteer_task_types", "effective_on"
    remove_column "volunteer_task_types", "ineffective_on"
  end
end
