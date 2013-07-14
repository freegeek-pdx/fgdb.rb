class CopyTaskTypeCountsFromReceiving < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      vtt = VolunteerTaskType.find_by_name('sorting')
      vtt2 = VolunteerTaskType.find_by_name('receiving')

      vtt2.ineffective_on = Date.today
      vtt2.save!
    end
  end

  def self.down
  end
end
