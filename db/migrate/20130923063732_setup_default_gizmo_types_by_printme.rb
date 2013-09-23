class SetupDefaultGizmoTypesByPrintme < ActiveRecord::Migration
  def self.up
    DB.exec("UPDATE types SET gizmo_type_id = (SELECT id FROM gizmo_types WHERE name LIKE 'laptop_mac') WHERE name LIKE 'apple_laptop';")
    DB.exec("UPDATE types SET gizmo_type_id = (SELECT id FROM gizmo_types WHERE name LIKE 'laptop') WHERE name LIKE 'laptop';")
    DB.exec("UPDATE types SET gizmo_type_id = (SELECT id FROM gizmo_types WHERE name LIKE 'server') WHERE name LIKE 'server';")
    DB.exec("UPDATE types SET gizmo_type_id = (SELECT id FROM gizmo_types WHERE name LIKE 'system_mac') WHERE name LIKE 'apple';")
  end

  def self.down
  end
end
