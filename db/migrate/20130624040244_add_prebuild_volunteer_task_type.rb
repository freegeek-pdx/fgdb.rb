class AddPrebuildVolunteerTaskType < ActiveRecord::Migration
  def self.up
    vtt = VolunteerTaskType.new
    vtt.description = 'laptop prebuild'
    vtt.name = 'laptop_prebuild'
    vtt.instantiable = true
    vtt.program_id = Program.find_by_name('build')
    vtt.adoption_credit = false
    vtt.save!
  end

  def self.down
  end
end
