class FixMiscAsIs < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      dt = DateTime.now

      gt = GizmoType.find_by_name("misc_item_as_is")
      gt.ineffective_on = dt
      gt.save!

      new = GizmoType.new
      new.description = "Miscellaneous Item--AS-IS"
      new.required_fee_cents = 0
      new.suggested_fee_cents = 0
      new.gizmo_category_id = 4
      new.name = "misc_item_as_is"
      new.covered = false
      new.rank = 99
      new.effective_on = dt
      new.parent_name = "gizmo"
      new.gizmo_contexts = [GizmoContext.sale]
      new.save!
    end
  end

  def self.down
  end
end
