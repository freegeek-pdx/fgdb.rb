class GenericsYetAgain < ActiveRecord::Migration
  def self.up
    only_serial = true
    [".       .              .", "To be filled by O.E.M.", "System serial number"].each{|x|
      g = Generic.find_by_value(x)
      if !g
        g = Generic.new
        g.only_serial = only_serial
        g.value = x
        g.save!
      end
    }

    only_serial = false
    ["Chassis Serial Number", "Chassis Manufacture", "System product name", "Ssystem manufacturer"].each{|x|
      g = Generic.find_by_value(x)
      if !g
        g = Generic.new
        g.only_serial = only_serial
        g.value = x
        g.save!
      else
        g.only_serial = only_serial
        g.save!
      end
    }
  end

  def self.down
  end
end
