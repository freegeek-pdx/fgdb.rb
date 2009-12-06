class AddMeetingJobType < ActiveRecord::Migration
  def self.up
    Job.create(:name => "Meeting")
  end

  def self.down
    Job.find_by_name("Meeting").destroy!
  end
end
