class AddMaxEffectiveHours < ActiveRecord::Migration
  def self.up
    Default['max_effective_hours'] = "24.0" if Default["is-pdx"] == "true"
  end

  def self.down
  end
end
