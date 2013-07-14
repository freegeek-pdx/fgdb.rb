class AddNewRenderingSystemType < ActiveRecord::Migration
  def self.up
    t = Type.new
    t.name = 'rendering'
    t.description = 'rendering'
    t.save!
  end

  def self.down
  end
end
