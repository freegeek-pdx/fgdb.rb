class DisktestAPI < SOAP::SoapsBase
  include ApplicationHelper

  def add_methods
    for i in soap_methods
      add_method(*i)
    end
  end

  def soap_methods
    [
    # soap_methods access
    ["soap_methods"],
    # Connection Testing
    ["ping"],
    # Lists
    ["add_disktest_started", "id", "started_at"],
    ["update_serial", "id", "serial"],
    ["add_disktest_completed_log", "id", "result", "completed_at", "details", "log"],
    ["new_disktest_run", "vendor", "model", "serial_number", "size", "bus_type"],
    ["check_disktest_running", "vendor", "model", "serial_number"],
    ["get_form_factor", "vendor", "model"],
    ["set_form_factor", "id", "form_factor"],
    ["get_batch_description", "serial"]

     # TODO: remove this later
    ["add_disktest_result", "id", "status"],
    ["add_disktest_completed", "id", "result", "completed_at", "details"],
    ["add_disktest_run", "vendor", "model", "serial_number", "size"],
    ]
  end

  ######################
  # Connection Testing #
  ######################

  def ping
#    return error("BOO")
    "pong"
  end

  #########
  # Lists #
  #########

  public
  def get_batch_description(serial)
    DisktestBatchDrive.find_active_by_serial(serial).map{|x| x.disktest_batch}.uniq.map{|x| x.long_description}.join(", ")
  end

  def get_form_factor(vendor, model)
    dr = DisktestRun.find(:first, :conditions => ["vendor ILIKE ? AND model ILIKE ? AND form_factor IS NOT NULL AND form_factor <> ''", vendor, model], :order => "updated_at DESC")
    return dr ? dr.form_factor : dr
  end

  def set_form_factor(id, form_factor)
    dr = DisktestRun.find(id.to_i)
    dr.form_factor = form_factor
    dr.save!
    return
  end

  def update_serial(id, serial)
    dr = DisktestRun.find(id.to_i)
    dr.serial_number = serial
    dr.save!
    return
  end

  def check_disktest_running(vendor, model, serial_number)
    return DisktestRun.is_running?(vendor, model, serial_number)
  end

  def add_disktest_started(id, started_at)
    dr = DisktestRun.find(id.to_i)
    dr.started_at = started_at
    dr.save!
    return
  end

  # TODO: remove this
  def add_disktest_completed(id, result, completed_at, details)
    dr = DisktestRun.find(id.to_i)
    dr.result = result
    dr.completed_at = completed_at
    dr.failure_details = details
    dr.save!
    return
  end

  def add_disktest_completed_log(id, result, completed_at, details, log)
    dr = DisktestRun.find(id.to_i)
    dr.result = result
    dr.completed_at = completed_at
    dr.failure_details = details
    dr.log = log
    dr.save!
    return
  end

  def new_disktest_run(vendor, model, serial_number, size, bus_type)
    dr = DisktestRun.new
    dr.vendor = vendor
    dr.model = model
    dr.serial_number = serial_number
    dr.megabytes_size = size
    dr.bus_type = bus_type
    dr.save!
    return dr.id
  end

  # TODO: REMOVE THIS
  def add_disktest_run(vendor, model, serial_number, size = nil)
    dr = DisktestRun.new
    dr.vendor = vendor
    dr.model = model
    dr.serial_number = serial_number
    dr.megabytes_size = size
    dr.start_time = Time.now
    dr.save!
    return dr.id
  end

  # TODO: REMOVE THIS
  def add_disktest_result(id, result)
    dr = DisktestRun.find(id.to_i)
    dr.result = result
    dr.completed_at = Time.now
    dr.save!
    return
  end
end
