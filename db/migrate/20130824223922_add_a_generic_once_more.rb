class AddAGenericOnceMore < ActiveRecord::Migration
  def self.up
    Generic.new(:value => ".........", :only_serial => false).save!
  end

  def self.down
  end
end
