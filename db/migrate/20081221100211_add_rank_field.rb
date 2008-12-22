class AddRankField < ActiveRecord::Migration
  def self.up
    add_column :gizmo_types, :rank, :integer
  end

  def self.down
    remove_column :gizmo_types, :rank
  end
end
