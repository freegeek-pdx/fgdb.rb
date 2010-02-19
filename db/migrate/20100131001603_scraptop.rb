class Scraptop < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      new = GizmoType.new
      new.description = "Scraptop--AS-IS"
      new.required_fee_cents = 0
      new.suggested_fee_cents = 0
      new.gizmo_category_id = 4
      new.name = "scraptop"
      new.covered = false
      new.rank = 99
      new.parent_name = "gizmo"
      new.gizmo_contexts = [GizmoContext.sale]
      new.save!
    end
  end

  def self.down
  end
end
