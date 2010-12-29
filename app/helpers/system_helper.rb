module SystemHelper
  class SystemParser
    attr_reader :processors, :l2_cache, :bios, :usb_supports, :drive_supports
    attr_reader :memories, :harddrives, :opticals, :pcis
    attr_reader :system_model, :system_serial_number, :system_vendor, :mobo_model, :mobo_serial_number, :mobo_vendor, :macaddr
    attr_reader :model, :vendor, :serial_number

    attr_reader :string, :parser, :myparser

    def SystemParser.parse(in_string)
      sp = nil
      parser = Parsers.select{|x| in_string.match(/#{x.match_string}/)}.first or return false
      begin
        sp = parser.new(in_string)
      rescue SystemParserException
        return false
      end
      return sp
    end

    def initialize(in_string)
      @string = in_string

      do_work

      if model_is_usable(@system_model)
        @model = @system_model
      elsif model_is_usable(@mobo_model)
        @model = @mobo_model
      else
        @model = "(no model)"
      end

      if vendor_is_usable(@system_vendor)
        @vendor = @system_vendor
      elsif vendor_is_usable(@mobo_vendor)
        @vendor = @mobo_vendor
      else
        @vendor = "(no vendor)"
      end

      if serial_is_usable(@system_serial_number)
        @serial_number = @system_serial_number
      elsif serial_is_usable(@mobo_serial_number)
        @serial_number = @mobo_serial_number
      elsif mac_is_usable(@macaddr)
        @serial_number = @macaddr
      else
        @serial_number = "(no serial number)"
      end
    end

    def find_system_id
      if @serial_number != "(no serial number)" && (found_system = System.find(:first, :conditions => {:serial_number => @serial_number, :vendor => @vendor, :model => @model}, :order => :id))
        return found_system.id
      else
        return nil
      end
    end

    def myparser
      self
    end

    private

    def is_usable(value, list_of_generics = [], check_size = false)
      return (value != nil && value != "" && !list_of_generics.include?(value) && (check_size == false || value.strip.length > 5))
    end

    def mac_is_usable(value)
      return is_usable(value)
    end

    def serial_is_usable(value)
      list_of_generics = Generic.find(:all).collect(&:value)
      return is_usable(value, list_of_generics, true)
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

  class SystemParserException < Exception
  end

  class LshwSystemParser < SystemParser
    include XmlHelper

    def self.match_string
      "generated by lshw"
    end

    attr_reader :parser # REMOVEME

    def do_work
      @parser = load_xml(@string) or raise SystemParserException
      # this will parse @string, and set @system.memories/etc

      @parser.xml_foreach("//*[@class='system']") {
        @system_model ||= @parser._xml_value_of("/node/product")
        @system_serial_number ||= @parser._xml_value_of("/node/serial")
        @system_vendor ||= @parser._xml_value_of("/node/vendor")
        @mobo_model ||= @parser._xml_value_of("//*[contains(@id, 'core')]/product")
        @mobo_serial_number ||= @parser._xml_value_of("//*[contains(@id, 'core')]/serial")
        @mobo_vendor ||= @parser._xml_value_of("//*[contains(@id, 'core')]/vendor")
        @macaddr ||= @parser._xml_value_of("//*[contains(@id, 'network') or contains(description, 'Ethernet')]/serial")
      }

      # TODO:     attr_reader :processors, :l2_cache, :bios, :usb_supports, :drive_supports
      # TODO:     attr_reader :memories, :harddrives, :opticals, :pcis
    end
  end


  class PlistSystemParser < SystemParser
    def self.match_string
      "DOCTYPE plist"
    end

    attr_reader :parser # REMOVEME

    include XmlHelper # REMOVEME

    def do_work
      @result = Nokogiri::PList(@string)
      @macaddr = @result.map{|x| x["_items"]}.flatten.select{|x| x["_name"] == "Built-in Ethernet"}.first["Ethernet"]["MAC Address"]
      @parser = load_xml(@string) # REMOVEME, just so that the page doesn't blow up since it still uses this for the other parser
    end
  end

  SystemParser::Parsers = [PlistSystemParser, LshwSystemParser]
end
