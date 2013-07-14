module SystemHelper
  class SystemParser
    attr_reader :processors, :bios, :usb_supports, :drive_supports
    attr_reader :l1_cache, :l2_cache, :l3_cache, :l1_cache_total, :l2_cache_total, :l3_cache_total
    attr_reader :total_memory, :maximum_memory, :memories, :harddrives, :opticals, :pcis
    attr_reader :system_model, :system_serial_number, :system_vendor, :mobo_model, :mobo_serial_number, :mobo_vendor, :macaddr
    attr_reader :model, :vendor, :serial_number
    attr_reader :battery_life
    attr_reader :sixty_four_bit, :virtualization, :north_bridge

    include XmlHelper

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

    def pricing_hash
      o = {}

      # "Processor Description" (vendor & product) ..?
      proc = @processors.select{|x| x.processor != "(N/A)"}.first
      if proc
        o[:processor_product] = proc.processor

        # "Running Speed",
        # "Real Speed" (DISPLAY WARNING if different)
        o[:running_processor_speed] = proc.speed.downcase if proc.speed

        m = o[:processor_product].match(/([0-9.]+\s*[GM]HZ)/i)
        o[:product_processor_speed] = m ? m[0].downcase : nil
      end
      o[:processor_count] = @processors.select{|x| x.processor != "(N/A)"}.length.to_s

      # "Max L2/L3 cache" (Add  all 'em up, but use only L3 if it's there else L2.)
      o[:max_l2_l3_cache] = (@l3_cache_total == "0B" ? @l2_cache_total : @l3_cache_total).downcase.sub(/kb/, "k")

      # AND "RAM total", cause it can differ? DISPLAY WARNING)
      o[:total_ram] = @total_memory ? @total_memory.downcase : ""
      o[:individual_ram_total] = @added_total.to_bytes(1).downcase
      mem_s = @memories.map{|x| x.description}.join(" ")
      o[:memory_type] = "Unknown"
      for i in ["DDR", "DDR2", "DDR2 FB-DIMM", "DDR3"]
        split = i.split(" ")
        if mem_s.match(/#{split[0]}/i) && (split[1].nil? || mem_s.match(/#{split[1]}/i))
          o[:memory_type] = i
        end
      end

      # "HD Size" (first, for now at least),
      if @harddrives.first
        o[:hd_size] = @harddrives.first.size
        o[:hd_size].downcase! unless o[:hd_size].nil? or o[:hd_size].match(/TB/)
        o[:hd_count] = @harddrives.count
        o[:hd_type] = @harddrives.first.my_type
        o[:hd_size_total] = @total_hd_size
        o[:hd_size_total].downcase! unless o[:hd_size_total].match(/TB/)
      end

      optic_cap = @opticals.collect{|x| (x.capabilities || "").split(/, (?:and )?/)}.flatten.uniq.to_sentence
      optic_models = @opticals.collect{|x| x.model}.uniq.to_sentence
      cdrw = optic_cap.match(/CD[- ]RW? burning/i) || optic_models.match(/CD[ -]R(?!ead|OM)/i) || optic_models.match(/CD[ -]?RW/i)
      dvdrw = optic_cap.match(/DVD[-+ ]RW? burning/i) || optic_models.match(/DVD[- +]R(?!ead|OM)/i)
      cdrom = optic_cap.match(/read CD-ROMs/i) || optic_models.match(/CD/i)
      dvd = optic_cap.match(/DVD playback/i) || optic_models.match(/DVD/i)
      if dvdrw
        o[:optical_drive] = "DVD/RW"
      elsif cdrw and dvd
        o[:optical_drive] = "Combo DVD CD/RW"
      elsif cdrw
        o[:optical_drive] = "CD/RW"
      elsif dvd
        o[:optical_drive] = "DVD Rom"
      elsif cdrom
        o[:optical_drive] = "CD Rom"
      else
        o[:optical_drive] = "N/A"
      end

      # Laptop Battery Life (mins)
      o[:battery_life] = @battery_life

      return o
    end

    def klass
      self.class
    end

    def initialize(in_string)
      @string = in_string

      @parser = load_xml(@string) or raise SystemParserException

      @added_total = 0
      @sixty_four_bit = false
      @virtualization = false
      @north_bridge = "Unknown"
      @processors = []
      @drive_supports = []
      @l1_cache = []
      @l2_cache = []
      @l3_cache = []
      @harddrives = []
      @memories = []
      @opticals = []
      @pcis = []
      @l1_cache_total = 0
      @l2_cache_total = 0
      @l3_cache_total = 0
      @total_hd_size = 0

      do_work

      @parser = nil
      @string = nil

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
      if @serial_number != "(no serial number)" && (found_system = System.find(:first, :conditions => {:serial_number => @serial_number, :vendor => @vendor, :model => @model}, :order => 'id DESC'))
        return found_system.id
      else
        return nil
      end
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

  class FgdbPrintmeExtrasSystemParser < SystemParser
    include XmlHelper

    def pricing_hash
      h = @real_system_parser.pricing_hash
      m = @battery_life.match(/battery lasted ([0-9]+ minutes)/) if @battery_life
      if m
        h[:battery_life] = m[1]
      end
      h
    end

    def self.match_string
      "fgdb_printme"
    end

    def klass
      @real_system_parser.klass
    end

    def do_work
      @parser.xml_foreach("//fgdb_data") {
        d = @parser.my_node.children.map{|x| x.to_s}.join("")
        @real_system_parser = SystemParser.parse(d)
      }
      @real_system_parser.instance_variables.each{|x|
        next if x == "@parser"
        self.instance_variable_set(x, @real_system_parser.instance_variable_get(x))
      }

      @parser.xml_foreach("//fgdb_printme") {
        @battery_life = @parser.xml_value_of("batterytest") if @parser.xml_if("batterytest")
        @maximum_memory = @parser.xml_value_of("max_capacity") if @parser.xml_if("max_capacity")
      }
    end
  end

  class LshwSystemParser < SystemParser
    include XmlHelper

    def self.match_string
      "generated by lshw"
    end

    def do_work
      # system data

      @parser.xml_foreach("//*[@class='system']") {
        @system_model ||= @parser._xml_value_of("//node[@class='system']/product")
        @system_serial_number ||= @parser._xml_value_of("//node[@class='system']/serial")
        @system_vendor ||= @parser._xml_value_of("//node[@class='system']/vendor")
        @mobo_model ||= @parser._xml_value_of("//*[contains(@id, 'core')]/product")
        @mobo_serial_number ||= @parser._xml_value_of("//*[contains(@id, 'core')]/serial")
        @mobo_vendor ||= @parser._xml_value_of("//*[contains(@id, 'core')]/vendor")
        @macaddr ||= @parser._xml_value_of("//*[contains(@id, 'network') or contains(description, 'Ethernet')]/serial")
      }

      # computer section

      @parser.xml_foreach("//*[@class='processor']") do
        if @parser.xml_if("product")
          h = OpenStruct.new
          h.slot = @parser.xml_value_of("slot")
          h.processor = @parser.xml_value_of("product")
          h.speed = (@parser.xml_if("capacity") && false ? @parser.xml_value_of("capacity") : @parser.xml_value_of("size")).to_hertz if @parser.xml_if("capacity") || @parser.xml_if("size")

          h.supports = []
          virts = ["svm", "vmx"]
          sixtyfours = ["lm", "x86-64"]
          find_these = virts + sixtyfours
          @parser.xml_foreach("capabilities/capability") do
            if find_these.include?(@parser.xml_value_of("@id"))
              h.supports << @parser.xml_value_of(".")
            end
            @virtualization = true if virts.include?(@parser.xml_value_of("@id"))
            @sixty_four_bit = true if sixtyfours.include?(@parser.xml_value_of("@id"))
          end
          @processors << h
        end
      end

      @parser.xml_foreach("//*[@handle='PCIBUS:0000:00']") do
        if @parser.xml_if("product")
          @north_bridge = @parser.xml_value_of("product")
        end
      end

      @bios = @parser.xml_value_of("//*[contains(@id, 'firmware')]/version")

      @parser.find_the_biggest("//node[contains(@id, 'usbhost')]/capabilities/capability", "USB ") do |value|
        @usb_supports = value
      end

      a = []; @parser.xml_foreach("//*[contains(@id, 'storage') or contains(@id, 'ide') or contains(@id, 'scsi')]") do a << @parser.xml_value_of(".//product") + @parser.xml_value_of(".//description") end
      a.collect{|x| if x.match(/(scsi|sata|ide)/i); $1.upcase; else nil; end}.delete_if{|x| x.nil?}.uniq.each do |x|
        @drive_supports << x
      end

      @parser.xml_foreach("//*[@class='memory']") do
        if @parser.xml_value_of("description") == "L1 cache"
          @l1_cache_total += @parser.xml_value_of("size").to_i
          @l1_cache << @parser.xml_value_of("size").to_bytes
        end
        if @parser.xml_value_of("description") == "L2 cache"
          @l2_cache_total += @parser.xml_value_of("size").to_i
          @l2_cache << @parser.xml_value_of("size").to_bytes # the description is always L2 cache
        end
        if @parser.xml_value_of("description") == "L3 cache"
          @l3_cache_total += @parser.xml_value_of("size").to_i
          @l3_cache << @parser.xml_value_of("size").to_bytes
        end
      end

      @l1_cache_total = @l1_cache_total.to_bytes
      @l2_cache_total = @l2_cache_total.to_bytes
      @l3_cache_total = @l3_cache_total.to_bytes

      # hard drives
      @parser.xml_foreach("//*[contains(@id, 'disk')]") do
        h = OpenStruct.new
        h.name = @parser.xml_value_of("logicalname")
        h.my_type = (@parser.do_with_parent do @parser.xml_value_of(".//product") + @parser.xml_value_of(".//description") end).match(/(scsi|sata|ide)/i) ? $1.upcase : "Unknown"
        h.vendor = @parser.xml_value_of("vendor")
        h.model = @parser.xml_value_of("product")
        h.size = @parser.xml_if("size") ? @parser.xml_value_of("size").to_bytes(0, false, false) : @parser.xml_if("capacity") ? @parser.xml_value_of("capacity").to_bytes(0, false, false) : nil
        @total_hd_size += @parser.xml_if("size") ? @parser.xml_value_of("size").to_i : @parser.xml_value_of("capacity").to_i
        h.volumes = []
        @parser.xml_foreach(".//*[contains(@id, 'volume')]") do
          v = OpenStruct.new
          v.name = @parser.xml_value_of("logicalname")
          v.description = @parser.xml_value_of("description")
          v.size = @parser.xml_value_of("capacity").to_bytes(0, false, false)
          h.volumes << v
        end
        @harddrives << h
      end
      @total_hd_size = @total_hd_size.to_bytes(0, false, false)

      # memory
      @parser.xml_foreach("//*[contains(@id, 'memory')]") do
        if @parser.xml_if("size")
          @total_memory = @parser.xml_value_of("size").to_bytes(1)
        end
      end

      @parser.xml_foreach(".//*[contains(@id, 'bank')]") do
        m = OpenStruct.new
        m.bank = @parser.xml_value_of("@id").sub(/^bank:/, "")
        m.description = @parser.xml_value_of("description")
        if @parser.xml_if("size")
          s = @parser.xml_value_of("size")
          @added_total += s.to_i
          m.size = s.to_bytes
        end
        @memories << m
      end

      # optical
      @parser.xml_foreach("//node[contains(@id, 'cdrom')]") do
        h = OpenStruct.new
        h.name = @parser.xml_value_of("logicalname")
        h.description = @parser.xml_value_of("description")
        a = []
        @parser.xml_foreach("capabilities/capability") do
          a << [@parser.xml_value_of("."), @parser.xml_value_of("@id")]
        end
        a = a.select{|a| a[1].match(/(cd|dvd)/i)}
        h.capabilities = a.map{|x| x[0]}.to_sentence
        h.my_type = (@parser.do_with_parent do @parser.xml_value_of("product") + @parser.xml_value_of("description") end).match(/(scsi|sata|ide)/i) ? $1.upcase : "Unknown"
        h.model = @parser.xml_value_of("product")
        @opticals << h
      end

      # pci
      @seen = []
      @seen_ser = []

      @parser.xml_foreach("//*[contains(@id, 'pci') or contains(@id, 'pcmcia')]") do
        h = OpenStruct.new
        h.title = @parser._xml_value_of("product")
        h.devices = []
        @parser.xml_foreach("./node[contains(@handle, 'PCI:') or contains(@handle, 'PCMCIA:')]") do
          if !['bus', 'bridge', 'storage', 'system', 'memory'].include?(@parser.xml_value_of("@class"))
            t = pci_stuff
            h.devices << t if t
          end
        end
        @pcis << h
      end

      h = OpenStruct.new
      h.title = "Unknown"
      h.devices = []
      @parser.xml_foreach("//node[not(@class='bus')
                      and not(@class='bridge')
                      and not(@class='storage')
                      and not(@class='system')
                      and not(@class='processor')
                      and not(@class='volume')
                      and not(@class='disk')
                      and not(@class='memory')]") do
        t = pci_stuff
        h.devices << t if t
      end
      @pcis << h

      @seen = nil
      @seen_ser = nil
    end

    private

    def pci_stuff
      my_id = @parser.my_node
      my_ser = @parser.xml_value_of("serial")
      my_ser = nil if my_ser == "Unknown"
      if @seen.include?(my_id) || (my_ser && @seen_ser.include?(my_ser))
        return false
      else
        @seen << my_id
        @seen_ser << my_ser if my_ser
      end

      d = OpenStruct.new
      d.my_type = @parser.xml_value_of("@class") if @parser.xml_if("@class")
      if @parser.xml_if("description")
        d.description = @parser.xml_value_of("description")
        handle = @parser.xml_value_of("@handle").sub(" ", "")
        if handle.length > 0
          d.description += " (#{ handle })"
        end
      end
      d.vendor = @parser.xml_value_of("vendor") if @parser.xml_if("vendor")
      d.product = @parser.xml_value_of("product") if @parser.xml_if("product")
      # if false && @parser.xml_value_of("@class")=="display" && @parser.xml_if("size") %><%# not tested after nokogiri %>
      # Video Ram: <%= @parser.xml_value_of("size").to_bytes %>
      # if false && @parser.xml_value_of("@class")=="network" && @parser.xml_if("configuration/setting[@id='wireless']")
      # Wireless Capabilities: <%= @parser.xml_value_of("configuration/setting[@id='wireless']/@value") %>
      # if false && @parser.xml_value_of("@class")=="network" && @parser.xml_if("logicalname") %><%# not tested after nokogiri %>
      # Ethernet Interface:  <%= @parser.xml_value_of("logicalname") %>
      if @parser.xml_value_of("@class")=="network" && @parser.xml_if("capabilities")
        @parser.find_the_biggest(".//capability/@id") do |value|
          d.speed = value.to_i.to_s.to_bitspersecond
        end
      end

      return d
    end
  end

  # TODO: replace open structs with actual struct classes shared by the parsers (so under the module)...this way we can ensure things are done without typos in code.

  class PlistSystemParser < SystemParser
    def self.match_string
      "<plist"
    end

    def snm(name)
      @items.select{|x| x[name]}.map{|x| x[name]}.first
    end

    def do_work
      @result = Nokogiri::PList::Parser.parse(@parser.my_node)
      items = @items = @result.map{|x| x["_items"]}.flatten.select{|x| x}
      t = items.select{|x| x["_name"] == "Built-in Ethernet"}.first
      @macaddr =  t["Ethernet"]["MAC Address"] if t && t["Ethernet"] && t["Ethernet"]["MAC Address"]
      @memories = items.select{|x| x["dimm_status"]}.map{|x|
        d = OpenStruct.new
        d.bank = x["_name"]
        d.description = x["dimm_type"] == "empty" ? x["dimm_type"] : [x["dimm_type"], x["dimm_speed"]].join(" ")
        d.size = x["dimm_size"]
        i = x["dimm_size"].to_i
        i *= (1024*1024) if x["dimm_size"].match(/m/i)
        i *= (1024*1024*1024) if x["dimm_size"].match(/g/i)
        @added_total += i
        d
      }
      @total_memory = items.select{|x| x["physical_memory"]}.first["physical_memory"].sub(/ /, "").sub(/^([0-9]+)gb/i) {$1 + ".0gb"}
      @l2_cache = items.select{|x| x["l2_cache_size"]}.map{|x| x["l2_cache_size"]}
      @l3_cache = items.select{|x| x["l3_cache_size"]}.map{|x| x["l3_cache_size"]}

      @l1_cache_total = "Unknown"
      @l2_cache_total = (@l2_cache.first || 0.to_bytes).gsub(/ /, "")
      @l3_cache_total = (@l3_cache.first || 0.to_bytes).gsub(/ /, "")

      items_items = items.map{|x| x["_items"]}.flatten.select{|x| !x.nil?}

      @harddrives = items_items.select{|x| x["removable_media"] == "no"}.map{|x|
        d = OpenStruct.new
        d.name = x["bsd_name"]
        d.model = x["device_model"]
        d.size = x["size"].sub(/ /, "")
        d.my_type = x["spata_protocol"]
#        d.vendor is in the model string
        d.volumes = []
        d
      }
      @total_hd_size = 0.to_bytes(0, false, false) # TODO ?
      @opticals = items_items.select{|x| x["spata_protocol"] == "atapi"}.map{|x|
        d = OpenStruct.new
        d.name = x["_name"]
        d.model = x["device_model"]
	d
      }
      numtimes = snm("number_processors") || snm("number_cpus")
      @system_serial_number = items.select{|x| x["serial_number"]}.map{|x| x["serial_number"]}.first
      numtimes.to_i.times do
        p = OpenStruct.new
        p.speed = items.select{|x| x["current_processor_speed"]}.map{|x| x["current_processor_speed"]}.first.sub(/ /, "").sub(/^([0-9]+)ghz/i) {$1 + ".00ghz"}.sub(/^([0-9]+.[0-9])ghz/i) {$1 + "0ghz"}
        p.processor = items.select{|x| x["cpu_type"]}.map{|x| x["cpu_type"]}.first
        p.slot = "Unknown"
        p.supports = []
        @processors << p
      end
      @system_model = "#{items.select{|x| x["machine_name"]}.map{|x| x["machine_name"]}.first} (#{ items.select{|x| x["machine_model"]}.map{|x| x["machine_model"]}.first })"
      @system_vendor = "Apple Computer, Inc."
      @pcis = [OpenStruct.new]
      @pcis.first.devices = []
      items.select{|x| ["Ethernet", "AirPort"].include?(x["_name"])}.each{|x|
        s = OpenStruct.new
	h = x["hardware"]
	if h.match(/airport/i)
	 q = items.select{|x| x["_name"] == "spairport_information"}.first #
	 h += " Extreme" if q && q["spairport_wireless_card_type"] && q["spairport_wireless_card_type"].match(/extreme/i)
	end
        s.description = h + " Interface"
        s.my_type = "network"
        s.name = x.inspect
        @pcis.first.devices << s
      }
      @result = nil
    end
  end

  SystemParser::Parsers = [FgdbPrintmeExtrasSystemParser, PlistSystemParser, LshwSystemParser]
end
