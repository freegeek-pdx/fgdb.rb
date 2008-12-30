class AddSomeSearchableFields < ActiveRecord::Migration
  def self.up
    add_column :books, :author, :string
    add_column :books, :title, :string
    add_column :books, :description, :text
    add_column :books, :isbn, :integer
  end

  def self.down
  end
end
