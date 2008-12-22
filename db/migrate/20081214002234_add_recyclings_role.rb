class AddRecyclingsRole < ActiveRecord::Migration
  def self.up
    r = Role.new
    r.name = "RECYCLINGS"
    r.save!
    Recycling.connection.execute("ALTER TABLE recyclings ALTER created_by SET NOT NULL")
  end

  def self.down
  end
end
