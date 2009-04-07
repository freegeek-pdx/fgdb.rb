module PrintmeHelper
  include XmlHelper

  def parse_stuff(my_lshw_output)
    @parser = load_xml(my_lshw_output) or return false

    @system_model = @system_serial_number = @system_vendor = @mobo_model = @mobo_serial_number = @mobo_vendor = @macaddr = nil

    @parser.xml_foreach("//*[@class='system']") {
      @system_model ||= @parser._xml_value_of("/node/product")
      @system_serial_number ||= @parser._xml_value_of("/node/serial")
      @system_vendor ||= @parser._xml_value_of("/node/vendor")
      @mobo_model ||= @parser._xml_value_of("//*[contains(@id, 'core')]/product")
      @mobo_serial_number ||= @parser._xml_value_of("//*[contains(@id, 'core')]/serial")
      @mobo_vendor ||= @parser._xml_value_of("//*[contains(@id, 'core')]/vendor")
      @macaddr ||= @parser._xml_value_of("//*[contains(@id, 'network')]/serial")
    }

    get_vendor
    get_serial
    get_model
    return @parser
  end

  def find_system_id
    if @serial_number != "(no serial number)" && (found_system = System.find(:first, :conditions => {:serial_number => @serial_number, :vendor => @vendor, :model => @model}, :order => :id))
      return found_system.id
    else
      return nil
    end
  end

  #######
  private
  #######

  def get_model
    if model_is_usable(@system_model)
      @model = @system_model
    elsif model_is_usable(@mobo_model)
      @model = @mobo_model
    else
      @model = "(no model)"
    end
    return @model
  end

  def get_vendor
    if vendor_is_usable(@system_vendor)
      @vendor = @system_vendor
    elsif vendor_is_usable(@mobo_vendor)
      @vendor = @mobo_vendor
    else
      @vendor = "(no vendor)"
    end
    return @vendor
  end

  def get_serial
    if serial_is_usable(@system_serial_number)
      @serial_number = @system_serial_number
    elsif serial_is_usable(@mobo_serial_number)
      @serial_number = @mobo_serial_number
    elsif mac_is_usable(@macaddr)
      @serial_number = @macaddr
    else
      @serial_number = "(no serial number)"
    end
    return @serial_number
  end

  def is_usable(value, list_of_generics = [])
    return (value != nil && value != "" && !list_of_generics.include?(value))
  end

  def mac_is_usable(value)
    return is_usable(value)
  end

  def serial_is_usable(value)
    list_of_generics = Generic.find(:all).collect(&:value)
    return is_usable(value, list_of_generics)
  end

  def vendor_is_usable(value)
    list_of_generics = Generic.find(:all, :conditions => ['only_serial = ?', false]).collect(&:value)
    return is_usable(value, list_of_generics)
  end

  def model_is_usable(value)
    list_of_generics = Generic.find(:all, :conditions => ['only_serial = ?', false]).collect(&:value)
    return is_usable(value, list_of_generics)
  end
end
