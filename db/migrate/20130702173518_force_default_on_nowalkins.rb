class ForceDefaultOnNowalkins < ActiveRecord::Migration
  def self.up
    DB.exec("UPDATE volunteer_events SET nowalkins = 'f';")
    change_column :volunteer_events, :nowalkins, :boolean, :default => false, :null => false
  end

  def self.down
  end
end
