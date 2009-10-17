class RemoveGizmoTypesNameUk < ActiveRecord::Migration
  def self.up
#    DB.execute("ALTER TABLE gizmo_types DROP INDEX gizmo_types_name_uk;")
    remove_index "gizmo_types", :name => "gizmo_types_name_uk"
  end

  def self.down
    add_index "gizmo_types", ["name"], :name => "gizmo_types_name_uk", :unique => true
  end
end
