class ReportLog < ActiveRecord::Base
  def self.add_to_log(name)
    r = ReportLog.new
    r.report_name = name
    if Thread.current['user']
      r.user_id = Thread.current['user'].id
    end
    r.save!
  end
end
