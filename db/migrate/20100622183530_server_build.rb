class ServerBuild < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      vtt = VolunteerTaskType.find_by_name("enterprise")
      vtt.name = "server"
      vtt.description = "server"
      vtt.save!
    end
  end

  def self.down
  end
end
