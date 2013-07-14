class CreateTechSupportNotes < ActiveRecord::Migration
  def self.up
    create_table :tech_support_notes do |t|
      t.integer :contact_id, :null => false, :unique => true
      t.text :notes

      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end

    add_foreign_key :tech_support_notes, :contact_id, :contacts, :id, :on_delete => :cascade
    add_foreign_key :tech_support_notes, :created_by, :users, :id, :on_delete => :restrict
    add_foreign_key :tech_support_notes, :updated_by, :users, :id, :on_delete => :restrict
  end

  def self.down
    drop_table :tech_support_notes
  end
end
