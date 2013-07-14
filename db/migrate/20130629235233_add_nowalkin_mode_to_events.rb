class AddNowalkinModeToEvents < ActiveRecord::Migration
  def self.up
    add_column :volunteer_events, :nowalkins, :boolean, :default => false
  end

  def self.down
  end
end
