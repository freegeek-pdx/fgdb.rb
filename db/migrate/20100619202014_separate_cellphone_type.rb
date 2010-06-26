class SeparateCellphoneType < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      old = GizmoType.find_by_name("pda_cell_phone")
      new = GizmoType.new(old.attributes)
      old.name = "pda_mp3"
      old.description = "PDA/MP3"
      new.name = "cell_phone"
      new.description = "Cell Phone"
      new.gizmo_contexts = old.gizmo_contexts
      new.save!
      old.save!
    end
  end

  def self.down
  end
end
