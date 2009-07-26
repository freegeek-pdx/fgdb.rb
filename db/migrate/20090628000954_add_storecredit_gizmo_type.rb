class AddStorecreditGizmoType < ActiveRecord::Migration
  def self.up
    new = GizmoType.new(:name => "store_credit", :description => "Store Credit", :gizmo_category => GizmoCategory.find_by_name("misc"), :required_fee_cents => 0, :suggested_fee_cents => 0)
    new.save!
    DB.execute("UPDATE gizmo_contexts_gizmo_types SET gizmo_type_id = #{new.id} WHERE gizmo_type_id IN (SELECT id FROM gizmo_types WHERE name = 'gift_cert');")
  end

  def self.down
    DB.execute("UPDATE gizmo_contexts_gizmo_types SET gizmo_type_id = (SELECT id FROM gizmo_types WHERE name = 'gift_cert') WHERE gizmo_type_id IN (SELECT id FROM gizmo_types WHERE name = 'store_credit');")
    GizmoType.find_by_name("store_credit").destroy
  end
end
