class DisktestBatchDrive < ActiveRecord::Base
  belongs_to :disktest_run
  belongs_to :disktest_batch
  belongs_to :user_destroyed_by, :class_name => "User"

#  validates_presence_of :serial_number, :unless => 'we_have_system?'
#  validates_presence_of :disktest_batch_id
#  validates_existence_of :disktest_batch

#  def we_have_system?
#    !! system_serial_number
#  end

  def validate
    errors.add('user_destroyed_by', 'is not authorized to mark drives destroyed') unless self.user_destroyed_by.nil? or self.user_destroyed_by.has_privileges('data_security')
  end

  def disktest_run
    DisktestRun.find_by_id(self.disktest_run_id) || (self.disktest_batch and self.disktest_batch.finalized ? nil : _find_run)
  end

  def _find_run
    return unless self.serial_number and self.serial_number.to_s.length > 0
    # Note: if this uses finalized ever, will need to change the ajax stuff
    DisktestRun.find_all_by_serial_number(self.serial_number).select{|x| x.created_at >= self.disktest_batch.date and x.result != 'UNTESTED'}.sort_by(&:created_at).last
  end

  def wiped?
    (!self.destroyed_at) and self.disktest_run and self.disktest_run.result == "PASSED"
  end

  def no_drive?
    return self.serial_number.downcase.strip == "no drive"
  end

  def destroyed?
    !! self.destroyed_at
  end

  def untested?
    not (wiped? or destroyed? or no_drive?)
  end

  def status
    self.no_drive? ? "No hard drive in system." : self.destroyed_at.nil? ? (self.disktest_run ? self.disktest_run.status.sub(/PASSED/, "Wiped") : "Not yet tested.") : "Destroyed at #{self.destroyed_at}"
  end

  def mark_destroyed
    self.user_destroyed_by = Thread.current['user']
    self.destroyed_at = Time.now
  end

  def status=(input)
    if input == "Will be marked destroyed"
      self.mark_destroyed
    end
  end

  def finalize_run
    run = _find_run
    self.disktest_run_id = run ? run.id : nil
  end
end
