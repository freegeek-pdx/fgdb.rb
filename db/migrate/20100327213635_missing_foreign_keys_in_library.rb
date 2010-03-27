class MissingForeignKeysInLibrary < ActiveRecord::Migration
  def self.up
    add_foreign_key "copies", "book_id", "books", "id", :on_delete => :restrict
    add_foreign_key "fields", "book_id", "books", "id", :on_delete => :cascade
    add_foreign_key "library_events", "contact_id", "contacts", "id", :on_delete => :restrict
    add_foreign_key "library_events", "copy_id", "copies", "id", :on_delete => :cascade
    add_foreign_key "xapian_jobs", "book_id", "books", "id", :on_delete => :cascade
  end

  def self.down
    remove_foreign_key "copies", "copies_book_id_fk"
    remove_foreign_key "fields", "fields_book_id_fk"
    remove_foreign_key "library_events", "library_events_contact_id_fk"
    remove_foreign_key "library_events", "library_events_copy_id_fk"
    remove_foreign_key "xapian_jobs", "xapian_jobs_book_id_fk"
  end
end
