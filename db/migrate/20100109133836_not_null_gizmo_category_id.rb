class NotNullGizmoCategoryId < ActiveRecord::Migration
  def self.up
    DB.execute("ALTER TABLE gizmo_types ALTER gizmo_category_id SET NOT NULL")
  end

  def self.down
  end
end
