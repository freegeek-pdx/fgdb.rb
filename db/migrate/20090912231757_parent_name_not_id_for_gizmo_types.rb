class ParentNameNotIdForGizmoTypes < ActiveRecord::Migration
  def self.up
    add_column :gizmo_types, :parent_name, :string
    DB.sql("UPDATE gizmo_types AS gtm SET parent_name = (SELECT name FROM gizmo_types AS gto WHERE gto.id = gtm.parent_id);")
    remove_column :gizmo_types, :parent_id
  end

  def self.down
  end
end
