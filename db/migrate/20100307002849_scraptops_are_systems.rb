class ScraptopsAreSystems < ActiveRecord::Migration
  def self.up
    DB.run("UPDATE gizmo_types SET gizmo_category_id = 1 WHERE name = 'scraptop';")
  end

  def self.down
  end
end
