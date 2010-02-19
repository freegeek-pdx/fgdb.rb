class AddSomeTaskTypes < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
    vt = VolunteerTaskType.new
    vt.name = 'av'
    vt.description = 'A/V'
    vt.parent_id = 24
    vt.save!
    vt = VolunteerTaskType.new
    vt.name = 'library'
    vt.description = 'Library'
    vt.parent_id = 17
    vt.save!
    end
  end

  def self.down
  end
end
