class AddMiscAsIsType < ActiveRecord::Migration
  def self.up
    if Default["is-pdx"] == true
    bb = GizmoType.find_by_name('bargain_bin')
    bb.ineffective_on = Date.today
    bb.save!
    new = GizmoType.new
    new.description = "Miscellaneous Item--AS-IS"
    new.required_fee_cents = 0
    new.suggested_fee_cents = 0
    new.gizmo_category_id = 4
    new.name = "misc_item_as_is"
    new.covered = false
    new.rank = 99
    new.gizmo_contexts = [GizmoContext.sale]
    new.save!
    end
  end

  def self.down
    if Default["is-pdx"] == true
    bb = GizmoType.find_by_name('bargain_bin')
    bb.ineffective_on = nil
    bb.save!
    new = GizmoType.find_by_name('misc_item_as_is')
    new.destroy
    end
  end
end
