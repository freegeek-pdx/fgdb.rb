class AddDueBackToDefaults < ActiveRecord::Migration
  def self.up
    d = Default.new
    d.name = "library_due_back_days"
    d.value = "14"
    d.save!
  end

  def self.down
    Default.find_by_name("library_due_back_days").destroy!
  end
end
