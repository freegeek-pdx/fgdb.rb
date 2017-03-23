require 'open3'

class CupsBSD
  def self.is_printer_ready(printer_name)
    return !! `lpq -P#{printer_name}`.match("#{printer_name} is ready")
  end

  def self.print_string(printer_name, receipt_text)
    output, status = Open3.capture2e("lpr -P#{printer_name}", :stdin_data => receipt_text)
    return output.empty? && status.exitstatus == 0
  end
end
