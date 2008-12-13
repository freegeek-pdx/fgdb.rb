class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :fields do |t|
      t.integer :book_id
      t.integer :field
      t.string :subfield
      t.string :data

      t.timestamps
    end
  end

  def self.down
    drop_table :fields
  end
end
