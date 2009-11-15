class AddVirtualFieldToWorkers < ActiveRecord::Migration
  def self.up
    add_column :workers, :virtual, :boolean, :default => false, :null => false
    Worker.find(:all, :conditions => ["name LIKE ?", "0%"]).each{|x|
      x.virtual = true
      x.save!
    }
  end

  def self.down
    remove_column :workers, :virtual
  end
end
