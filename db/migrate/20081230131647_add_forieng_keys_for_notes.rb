class AddForiengKeysForNotes < ActiveRecord::Migration
  def self.up
    add_foreign_key "notes", ["contact_id"], "contacts", ["id"]
    add_foreign_key "notes", ["system_id"], "systems", ["id"]
  end

  def self.down
    remove_foreign_key "notes", "notes_contact_id_fk"
    remove_foreign_key "notes", "notes_system_id_fk"
  end
end
