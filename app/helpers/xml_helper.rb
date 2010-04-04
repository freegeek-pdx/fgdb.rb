#!/usr/bin/ruby

class String
  def to_bytes(precision = 0, exact = true, truncate = true, yikes_until = "G")
    name, div = find_unit(exact)
    val = nil
    if !gte(name, yikes_until)
      precision = 0
      truncate = false
    end
    val = yikes(div, precision, truncate)
    ret = val + name + "B"
  end

  def to_bitspersecond
    name, div = find_unit(false, "M")
    val = yikes(div, 0, false)
    ret = val + name + "bps"
  end

  def to_hertz
    name, div = find_unit
    val = nil
    if gte(name, "G")
      val = yikes(div, 2)
    else
      val = yikes(div, 0, false)
    end
    ret = val + name + "Hz"
  end

  #######
#  private
  #######

  def my_float
    @my_float ||= self.to_f
  end

  def unit_arr
    a = ["", "K", "M", "G", "T", "P", "E", "Z", "Y"]
  end

  def gte(v, l)
    a = unit_arr
    hit_g = false
    for x in a
      if x == l
        hit_g = true
      end
      if x == v
        return hit_g
      end
    end
    raise ArgumentError
  end

  def find_unit(exact = false, base = "")
    number = my_float
    a = unit_arr
    base_div = exact ? 1024 : 1000
    start_i = -1
    i = 0
    for x in a
      if x == base
        start_i = i
        break
      end
      i += 1
    end
    if start_i == -1
      raise ArgumentError
    end
    number = number * (base_div ** start_i)
    i = 0
    final_i = -1
    for x in a
      n = number / (base_div ** i)
      if n < 1.0
        final_i = i - 1
        break
      end
      i += 1
    end
    if final_i == -1
      final_i = 0
    end
    found_name = a[final_i]
    found_divisor = base_div ** (final_i - start_i)
    return [found_name, found_divisor]
  end

  def yikes(divide_by, precision = 0, truncate = true)
    f = nil
    if truncate
      f = ((((my_float/divide_by)*(10**precision)).to_i).to_f)/(10**precision)
    else
      f = my_float / divide_by
    end
    return sprintf("%.#{precision}f", f)
  end
end

module XmlHelper
  class XmlParser
    def my_node
      @my_node
    end

    def do_with_parent
      temp = @my_node
      @my_node = temp.parent
      val = yield
      @my_node = temp
      return val
    end

    def xml_if(xpath = nil)
      if _xml_value_of(xpath) == nil
        return false
      else
        return true
      end
    end

    def xml_get_matches(xpath)
      @my_node.xpath(xpath)
    end

    def xml_first(xpath)
      oldnode = @my_node
      @my_node = xml_get_matches(xpath).first
      val = yield
      @my_node = oldnode
      return val
    end

    def xml_foreach(xpath)
      oldnode = @my_node
      for i in xml_get_matches(xpath)
        @my_node = i
        yield
      end
      @my_node = oldnode
      nil
    end

    def xml_value_of(thing = nil)
      if xml_if(thing)
        return _xml_value_of(thing)
      else
        return "Unknown"
      end
    end

    def _xml_value_of(xpath)
      begin
        if xpath.nil?
          return @my_node.content
        else
          return @my_node.xpath(xpath).first.content
        end
      rescue
        return nil
      end
    end

    def find_the_biggest(xpath, get_rid_of = "", &block)
      array = [0.0]
      xml_foreach(xpath) do
        this_value = xml_value_of.gsub(/#{get_rid_of}/, '').to_f
        array << this_value
      end
      value = array.max
      if value != 0.0
        return yield(value)
      else
        return nil
      end
    end

    def initialize(xml)
      super()
      if xml.nil? || xml.blank?
        raise BadXml
      end
      state = false
      begin
        @my_node = Nokogiri::XML(xml)
        state = true
      rescue
      end
      raise BadXml if state == false
      return self
    end
  end

  def load_xml(xml)
    begin
      x = XmlParser.new(xml)
    rescue BadXml
      return false
    end
    x
  end

  class BadXml < StandardError
  end
end

##########################
#test program starts here
##########################

def load_file(file = "file.xml")
  include XmlHelper

  f = open(file, 'r')
  if !(f.read)
    puts "failed"
    exit 1
  end
  f.close
end

if __FILE__ == $0
  if ARGV[0] == nil
    $stderr.puts "Usage: sax.rb file.xml"
    exit 1
  end

  load_file(ARGV[0])

  #  puts my_node.to_s

  #  my_node.match_by_id("disk").each {|x|
  #  puts x.to_s
  #  }

  #  my_node.find_by_class("processor").each {|x|
  #  puts x.to_s
  #  }

  my_node.find_by_element("node", "//").first.find_by_element("description", "/").each {|x|
    puts x.to_s
  }
end
