class AddAGeneric < ActiveRecord::Migration
  def self.up
    Generic.new(:value => "System Serial Number", :usable => true, :only_serial => false).save!
    Generic.new(:value => "System Product Name", :usable => true, :only_serial => false).save!
    Generic.new(:value => "System manufacturer", :usable => true, :only_serial => false).save!
    Generic.new(:value => "stem manufacturer", :usable => true, :only_serial => false).save!
  end

  def self.down
  end
end
