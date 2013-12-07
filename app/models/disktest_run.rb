class DisktestRun < ActiveRecord::Base
  def self.is_running?(vendor, model, serial)
    last = self.find_last_run(vendor, model, serial)
    return !! (last && last.running?)
  end

  def self.find_last_run(vendor, model, serial)
    self.find_all_by_vendor_and_model_and_serial_number(vendor, model, serial).sort_by(&:created_at).last
  end

  def display_size
    megabytes_size ? (megabytes_size*1024*1024).to_bytes(1, true, false) : nil
  end

  def running?
    result == nil
  end

  def status
    if running?
      "Testing since #{self.started_at.to_s}"
    elsif self.completed_at.nil?
      self.result
    else
      "#{self.result} at #{self.completed_at.to_s}"
    end
  end
end
