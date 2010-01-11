class AddVirtualToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :virtual, :boolean, :default => false, :null => false
    Job.find(:all, :conditions => ["name LIKE ?", "0%"]).each{|x|
      x.virtual = true
      x.save!
    }
  end

  def self.down
    remove_column :jobs, :virtual
  end
end
