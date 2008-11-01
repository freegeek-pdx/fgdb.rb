class SpecSheet < ActiveRecord::Base
  include XmlHelper

  acts_as_userstamp

  validates_presence_of :contact_id
  validates_presence_of :action_id
  validates_presence_of :type_id

  belongs_to :contact
  belongs_to :action
  belongs_to :system
  belongs_to :type
  has_one :contract, :through => :system

  validates_existence_of :type
  validates_existence_of :action
  validates_existence_of :contact

  named_scope :good, :conditions => ["cleaned_valid = ? AND original_valid = ?", true, true]
  named_scope :bad, :conditions => ["cleaned_valid = ? AND original_valid = ?", false, false]
  named_scope :originally_bad, :conditions => ["cleaned_valid = ? AND original_valid = ?", true, false]
  named_scope :clean_broke_it, :conditions => ["cleaned_valid = ? AND original_valid = ?", false, true]

  attr_accessor :contract_id

  before_save :set_contract_id
  def set_contract_id
    if system
      if !(@contract_id.nil? || !(c = Contract.find(@contract_id)))
        system.contract = c
        system.save!
      end
      if system.contract.nil?
        errors.add("system", "contract is not valid")
      end
    end
  end

  def lshw_output=(val)
    # if this record has already been saved, then don't let it change.
    if id.nil?
      self._lshw_output=(val)
    end
  end

  def _lshw_output=(val)
    write_attribute(:original_output, val)
    file = Tempfile.new("fgss-xml")
    file.write(original_output)
    file.flush
    write_attribute(:original_valid, Kernel.system("xmlstarlet val #{file.path} >/dev/null 2>/dev/null"))
    write_attribute(:cleaned_output, val.gsub(/[^[:print:]\n\t]/, ''))
    file = Tempfile.new("fgss-xml")
    file.write(cleaned_output)
    file.flush
    write_attribute(:cleaned_valid, Kernel.system("xmlstarlet val #{file.path} >/dev/null 2>/dev/null"))
  end

  def lshw_output
    if cleaned_valid
      return cleaned_output
    elsif original_valid
      return original_output
    else
      return ""
    end
  end

  def xml_is_good
    cleaned_valid || original_valid
  end

  def initialize(*args)
    super(*args)

    if !xml_is_good
      self.system_id = nil
      return
    end

    @parser = load_xml(lshw_output)

    @parser.xml_foreach("class", "system") {
      @system_model ||= @parser._xml_value_of("product", '/')
      @system_serial_number ||= @parser._xml_value_of("serial", '/')
      @system_vendor ||= @parser._xml_value_of("vendor", '/')
      @mobo_model ||= @parser.xml_first("id", "core") do @parser._xml_value_of("product", '/') end
      @mobo_serial_number ||= @parser.xml_first("id", "core") do @parser._xml_value_of("serial", '/') end
      @mobo_vendor ||= @parser.xml_first("id", "core") do @parser._xml_value_of("vendor", '/') end
      @macaddr ||= @parser.xml_first("id", "network") do @parser._xml_value_of("serial", '/') end
    }

    get_vendor
    get_serial
    get_model

    if @serial_number != "(no serial number)" && (found_system = System.find(:first, :conditions => {:serial_number => @serial_number, :vendor => @vendor, :model => @model}, :order => :id))
      self.system = found_system
    else
      self.system = System.new
      system.system_model  = @system_model
      system.system_serial_number  = @system_serial_number
      system.system_vendor  = @system_vendor
      system.mobo_model  = @mobo_model
      system.mobo_serial_number  = @mobo_serial_number
      system.mobo_vendor  = @mobo_vendor
      system.model  = @model
      system.serial_number  = @serial_number
      system.vendor  = @vendor
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
