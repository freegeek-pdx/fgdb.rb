class NewYearGizmos < ActiveRecord::Migration
  def self.up
    keyboard = GizmoType.find_by_name("keyboard")
    keyboard.covered = true
    keyboard.save!

    mouse = GizmoType.find_by_name("mouse")
    mouse.covered = true
    mouse.save!

    printer = GizmoType.find_by_name("printer")
    printer.description = "Printer, Regular"
    printer.covered = true
    printer.save!

    av_per = GizmoType.new
    av_per.name = "floor_printer"
    av_per.parent_name = "printer"
    av_per.required_fee_cents = 0
    av_per.suggested_fee_cents = 600
    av_per.gizmo_category_id = 3
    av_per.description = "Printer, Floor"
    av_per.covered = false
    av_per.rank = 99
    av_per.needs_id = false
    av_per.not_discounted = false
    av_per.gizmo_contexts = [GizmoContext.donation]
    av_per.save!

    av = GizmoType.find_by_name("av_gizmo")
    av.description = "A/V Receiver"
    av.save!

    av_per = GizmoType.new
    av_per.name = "av_peripheral"
    av_per.parent_name = "av_gizmo"
    av_per.required_fee_cents = 0
    av_per.suggested_fee_cents = 400
    av_per.gizmo_category_id = 4
    av_per.description = "A/V Peripheral"
    av_per.covered = false
    av_per.rank = 99
    av_per.needs_id = false
    av_per.not_discounted = false
    av_per.gizmo_contexts = [GizmoContext.donation]
    av_per.save!

    # Bag/Box Misc
    for i in ['card', 'drive_other', 'hard_drive', 'cd_burner', 'motherboard', 'power_supply', 'ram', 'fax_machine', 'scanner', 'mult_printer', 'system_crt_mac', 'system_crt', 'system_lcd_mac', 'system_mac', 'laptop_mac', 'speaker_set', 'phone', 'cell_phone', 'camera', 'ereader', 'pda', 'laptop_bag']
      gt = GizmoType.find_by_name(i)
      gt.gizmo_contexts -= [GizmoContext.donation]
      gt.save!
    end

    # TODO: move Tablet and Smart Phone to a new Mobile category
  end

  def self.down
  end
end
