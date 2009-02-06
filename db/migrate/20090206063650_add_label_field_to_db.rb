class AddLabelFieldToDb < ActiveRecord::Migration
  def self.up
    d = Default.new
    d.name = "label_type"
    d.value = "5662" # 5962 is what ours actually is..hope this is close enough.
    d.save!
  end

  def self.down
    Default.find_by_name("label_type").destroy!
  end
end
