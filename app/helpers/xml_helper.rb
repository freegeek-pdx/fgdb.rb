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
  class SaxParser
    attr_accessor :thing

    def initialize(xml)
      @parser = XML::SaxParser.new
      @parser.string = (xml || "")
      @parser.callbacks = Handler.new
    end

    def to_s
      @thing.to_s
    end

    def parse
      begin
        @parser.parse
        @thing = @parser.callbacks.thing
        return true
      rescue
        return false
      end
    end
  end

  class Node
    attr_accessor :parent, :element, :children, :attrs, :content

    #debugging
    def to_s(indent = "")
      string = indent + element + "\n"
      attrses = []
      (@attrs || {}).each { |k, v|
        attrses << [k, v].join("=")
      }
      attrses.each {|attr|
        string += " " + indent + attr + "\n"
      }
      if @content && @content != nil && @content != "" && !@content.match("^[ ]+$")
        string += " " + indent + @content + "\n"
      end
      for child in @children
        string += child.to_s(indent + " ")
      end
      return string
    end

    def initialize
      @children = []
    end

    def match_by_id(id, type = '//', array = nil)
      if array == nil
        array = []
        first = true
      else
        first = false
      end
      if attrs['id'] and element == "node"
        array << self if attrs['id'].match(/#{id}/)
      end
      if type == '//' || (type == '/' && first)
        for child in @children
          child.match_by_id(id, type, array)
        end
      end
      return array
    end

    def find_by_class(klass, type = '//', array = nil)
      if array == nil
        array = []
        first = true
      else
        first = false
      end
      if attrs['class'] and element == "node"
        array << self if attrs['class'] == klass
      end
      if type == '//' || (type == '/' && first)
        for child in @children
          child.find_by_class(klass, type, array)
        end
      end
      return array
    end

    def match_by_handle(handle, type = '//', array = nil)
      if array == nil
        array = []
        first = true
      else
        first = false
      end
      if attrs['handle'] and element == "node"
        array << self if attrs['handle'].match(/#{handle}/)
      end
      if type == '//' || (type == '/' && first)
        for child in @children
          child.match_by_handle(handle, type, array)
        end
      end
      return array
    end

    def find_by_element(a_element, type = '//', array = nil)
      if array == nil
        array = []
        first = true
      else
        first = false
      end
      if element
        array << self if a_element == element
      end
      if type == '//' || (type == '/' && first)
        for child in @children
          child.find_by_element(a_element, type, array)
        end
      end
      return array
    end
  end

  class Handler
    attr_accessor :elements, :thing

    def add_node(element, attrs)
      oldnode = @thing
      @thing = Node.new
      @thing.element = element
      @thing.parent = oldnode
      @thing.attrs = attrs
      oldnode.children << @thing
    end

    def on_characters(characters = '')
      @thing.content = characters
    end

    def remove_node(element)
      #debugging
      #    (puts "OOPS: #{element}"; return) if @thing == nil
      #    (puts "OOPS: #{element} #{@thing.element}"; return) if @thing.element != element
      raise if @thing == nil || @thing.element != element
      oldnode = @thing
      @thing = oldnode.parent
    end

    def initialize
      @elements = []
      @special = Node.new
      @special.element = "I'm sooooo special!!!!"
      @thing = @special
    end

    def on_start_element(element, attributes)
      add_node(element, attributes)
    end

    def on_end_element(element)
      remove_node(element)
    end

    def on_end_document
      temp = @thing
      remove_node(@special.element)
      @thing = temp.children[0]
    end

    # The complete chain is:
    #   on_start_document
    #   on_processing_instruction(instruction, arguments)
    #   on_start_element(element, attributes)
    #   on_characters(characters = '')
    #   on_end_element(element)
    #   on_end_document
    def method_missing(method_name, *attributes, &block)
    end
  end

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

    def xml_if(thing = nil, type = '//')
      if _xml_value_of(thing, type) == nil
        return false
      else
        return true
      end
    end

    def xml_get_matches(type, value, find_type = '//')
      case type
      when 'class':
          method = 'find_by_class'
      when 'handle':
          method = 'match_by_handle'
      when 'id':
          method = 'match_by_id'
      when 'element':
          method = 'find_by_element'
      else
        raise NoMethodError
      end
      return eval("@my_node.#{method}(value, find_type)")
    end

    def xml_first(type, value, find_type = '//')
      oldnode = @my_node
      @my_node = xml_get_matches(type, value, find_type).first
      val = yield
      @my_node = oldnode
      return val
    end

    def xml_foreach(type, value, find_type = '//')
      oldnode = @my_node
      for i in xml_get_matches(type, value, find_type)
        @my_node = i
        yield
      end
      @my_node = oldnode
      nil
    end

    def xml_value_of(thing = nil, type = '//')
      if xml_if(thing)
        return _xml_value_of(thing, type)
      else
        return "Unknown"
      end
    end

    def _xml_value_of(thing, type = '//')
      begin
        case thing
        when nil:
            return @my_node.content
        when /^@/:
            return @my_node.attrs[thing.sub(/@/, "")]
        else
          return @my_node.find_by_element(thing, type).first.content
        end
      rescue
        return nil
      end
    end

    def find_the_biggest(type, value, thingy, get_rid_of = "", &block)
      array = [0.0]
      xml_foreach(type, value) do
        this_value = xml_value_of(thingy).gsub(/#{get_rid_of}/, '').to_f
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
      @sax = SaxParser.new(xml)
      state = @sax.parse
      @my_node = @sax.thing
      if state == false
        raise BadXml
      end
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
