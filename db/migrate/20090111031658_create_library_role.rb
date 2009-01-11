class CreateLibraryRole < ActiveRecord::Migration
  def self.up
    r = Role.new
    r.name = "LIBRARIAN"
    r.save!
  end

  def self.down
    Role.find_by_name("LIBRARIAN").destroy
  end
end
