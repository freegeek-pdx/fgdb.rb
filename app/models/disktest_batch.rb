class DisktestBatch < ActiveRecord::Base
  belongs_to :contact
  has_many :disktest_batch_drives, :class_name => "DisktestBatchDrive", :autosave => true, :dependent => :destroy
  belongs_to :user_finalized_by, :class_name => "User"

  validates_presence_of :name
  validates_presence_of :date
  validates_presence_of :contact_id
  validates_existence_of :contact

  def long_description
    "Batch called " + self.name.to_s + ", for contact #" + self.contact_id.to_s + ", from " + self.date.to_s
  end

  def fake_status(serial)
    drive = self.disktest_batch_drives.new(:serial_number => serial)
    drive.disktest_batch = self
    drive.disktest_run = drive._find_run
    return drive.status
  end

  def count_number(sym)
    self.disktest_batch_drives.select{|x| x.send(sym)}.length
  end

  def validate
    errors.add('disktest_batch_drives', 'are not all tested or destroyed, report cannot be finalized') if self.finalized and self.count_number(:untested?) > 0
    errors.add('user_finalized_by', 'is not authorized to finalize reports') unless self.user_finalized_by.nil? or self.user_finalized_by.has_privileges('data_security')
  end

  def finalized
    !! self.finalized_on
  end

  def finalized=(value)
    if value and value == "1"
      self.user_finalized_by = Thread.current['user']
      self.finalized_on = Date.today
      self.disktest_batch_drives.each do |d|
        d.finalize_run
      end
    else
      self.user_finalized_by = nil
      self.finalized_on = nil
      self.disktest_batch_drives.each do |d|
        d.disktest_run_id = nil
      end
    end
  end
end
