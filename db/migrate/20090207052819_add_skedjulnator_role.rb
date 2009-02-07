class AddSkedjulnatorRole < ActiveRecord::Migration
  def self.up
    r = Role.new
    r.name = "SKEDJULNATOR"
    r.save!
  end

  def self.down
    r.find_by_name("SKEDJULNATOR").destroy!
  end
end
