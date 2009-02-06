class AddLibraryStuff < ActiveRecord::Migration
  def self.up
    create_table "copies", :force => true do |t|
      t.integer  "barcode"
      t.integer  "book_id"
      t.integer  "copy_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "books", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "fields", :force => true do |t|
      t.integer  "book_id"
      t.integer  "field"
      t.string   "subfield"
      t.string   "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "library_events", :force => true do |t|
      t.integer  "contact_id"
      t.integer  "kind",       :null => false
      t.datetime "date",       :null => false
      t.integer  "copy_id",    :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "due_back"
      t.integer  "created_by"
    end
  end

  def self.down
    drop_table :library_events
    drop_table :copies
    drop_table :books
    drop_table :fields
  end
end
