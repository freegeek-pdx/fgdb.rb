class FixCoveredUncoverables < ActiveRecord::Migration
  def self.up
    DB.execute("UPDATE gizmo_events AS ge SET covered = 'f' FROM gizmo_types AS gt WHERE ge.gizmo_type_id = gt.id AND (gt.covered = 'f' OR gt.covered IS NULL) AND ge.covered = 't';");
  end

  def self.down
  end
end
