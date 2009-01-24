class AddSomeSearchableFields < ActiveRecord::Migration
  def self.up
    add_column :books, :author, :string
    add_column :books, :title, :string
    add_column :books, :description, :text
    add_column :books, :isbn, :string # BAD. we need to just not use these.
  end

  def self.down
  end
end
