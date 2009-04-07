#!/usr/bin/ruby

class String
  def to_bytes(precision = 0, exact = true, truncate = true)
    if self.to_f/(exact ? 1048576 : 1000000) >= (exact ? 1024 : 1000)
      sprintf("%.#{precision}f", truncate ? yikes((exact ? 1073741824 : 1000000000), precision) : self.to_f/(exact ? 1073741824 : 1000000000)) + "GB"
    else
      sprintf("%.0f", self.to_f/(exact ? 1048576 : 1000000)) + "MB"
    end
  end

  def to_bitspersecond
    if self.to_i >= 1000
      (self.to_i/1000).to_s + "Gbps"
    else
      self + "Mbps"
    end
  end

  def to_hertz
    if self.to_f/1000000 >= 1000
      sprintf("%.2f", yikes(1000000000, 2)) + "GHz" #truncate...
    else
      sprintf("%.0f", self.to_f/1000000) + "MHz"
    end
  end

  #######
  private
  #######

  def yikes(divide_by, precision) #divides and then truncates.
    return ((((self.to_f/divide_by)*(10**precision)).to_i).to_f)/(10**precision)
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
