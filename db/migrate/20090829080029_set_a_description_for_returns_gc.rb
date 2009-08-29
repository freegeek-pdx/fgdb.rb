class SetADescriptionForReturnsGc < ActiveRecord::Migration
  def self.up
    DB.execute("UPDATE gizmo_contexts SET description = 'return' WHERE name = 'gizmo_return';")
  end

  def self.down
  end
end
