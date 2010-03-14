class AddFieldForSystemTypes < ActiveRecord::Migration
  def self.up
    add_column :gizmo_types, :needs_id, :boolean, :null => false, :default => false
    (GizmoType.find_all_by_gizmo_category_id(GizmoCategory.find_by_name("system").id) - GizmoType.find_all_by_name(["case", "scraptop"])).each{|x|
      x.needs_id = true
      x.save!
    }
  end

  def self.down
    remove_column :gizmo_types, :needs_id
  end
end
