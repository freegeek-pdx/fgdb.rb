class AddHardwareGrantsVolunteerType < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      vt = VolunteerTaskType.new
      vt.name = 'hardware_grants'
      vt.description = 'Hardware Grants'
      vt.parent_id = 17
      vt.save!
    end
  end

  def self.down
  end
end
