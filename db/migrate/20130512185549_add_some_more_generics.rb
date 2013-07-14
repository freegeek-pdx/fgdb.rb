class AddSomeMoreGenerics < ActiveRecord::Migration
  def self.up
    for i in ["NoneNoneNoneNone", ":[", "April197"]
      g = Generic.find_or_create_by_value(i)
      g.usable = true
      g.only_serial = false
      g.save!
    end
  end

  def self.down
  end
end
