class AddMultPrinterToPlaces < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      gt = GizmoType.find_by_name("mult_printer")
      gt.gizmo_contexts << GizmoContext.sale
      gt.gizmo_contexts << GizmoContext.recycling
      gt.save!
    end
  end

  def self.down
  end
end
