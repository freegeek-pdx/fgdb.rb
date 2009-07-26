class AddTechSupportRole < ActiveRecord::Migration
  def self.up
    Role.new(:name => "TECH_SUPPORT").save!
  end

  def self.down
    Role.find_by_name("TECH_SUPPORT").destroy
  end
end
