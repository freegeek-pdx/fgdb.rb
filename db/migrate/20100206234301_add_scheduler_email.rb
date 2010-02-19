class AddSchedulerEmail < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      Default["scheduler_reports_to"] = "schedule@lists.freegeek.org"
    end
  end

  def self.down
  end
end
