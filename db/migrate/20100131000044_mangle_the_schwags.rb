class MangleTheSchwags < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      dt = DateTime.now

      gt = GizmoType.find_by_name("schwag")
      gt.ineffective_on = dt
      gt.save!

      new = GizmoType.new
      new.description = gt.description
      new.required_fee_cents = gt.required_fee_cents
      new.suggested_fee_cents = gt.suggested_fee_cents
      new.gizmo_category_id = gt.gizmo_category_id
      new.name = gt.name
      new.covered = gt.covered
      new.rank = gt.rank
      new.effective_on = dt
      new.parent_name = "gizmo"
      new.gizmo_contexts = gt.gizmo_contexts
      new.save!

      cd = GizmoType.find_by_name("distro_cd")
      cd.parent_name = "schwag"
      cd.save!

      new = GizmoType.new
      new.description = "Ubuntu Book"
      new.required_fee_cents = 0
      new.suggested_fee_cents = 0
      new.gizmo_category_id = 4
      new.name = "ubuntu_book"
      new.covered = false
      new.rank = 99
      new.parent_name = "schwag"
      new.gizmo_contexts = [GizmoContext.sale]
      new.save!
    end
  end

  def self.down
  end
end
