class TrackCoveredOnPrintme < ActiveRecord::Migration
  def self.up
    add_column :systems, :covered, :boolean
  end

  def self.down
    remove_column :systems, :covered
  end
end
