class AddMacLaptopType < ActiveRecord::Migration
  def self.up
    t = Type.new
    t.name = "apple_laptop"
    t.description = "apple laptop"
    t.save!
  end

  def self.down
  end
end
