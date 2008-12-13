#!/usr/bin/ruby

require 'yaml'

def get_hash
  output = `./lookup.rb #{ARGV.join(" ")}`
  output = output.split("\n").collect{|x| x.chomp}
  @hash = {}
  output.each{|x|
    code = x.match(/^[0-9]{3} [a-z]/).to_s.sub(" ", "")
    body = x.sub(/^... . /, "")
    if @hash[code] && @hash[code].class != Array
      temp = @hash[code]
      @hash[code] = []
      @hash[code] << temp
      @hash[code] << body
    elsif @hash[code].class == Array
      @hash[code] << body
    else
      @hash[code] = body
    end
  }
end

get_hash

def print_thing(name, thing)
  xml = @hash[thing]
  newname = name.downcase.gsub(/ /, "_")
  if xml
    @order << newname
    @origs[newname] = name
    @res[newname] = xml
  end
end

def cleanup
  @res["title"].sub!(/ \/$/, "") if @res["title"].class == String
  @res["author"].sub!(/[.,]$/, "") if @res["author"].class == String
  @res["publisher"].sub!(/,$/, "") if @res["publisher"].class == String
  @res["place_of_publication"].sub!(/ ;$/, "") if @res["place_of_publication"].class == String
  @res.each{|k,v|
    if v.class == String
      @res[k] = v.sub(/ [;:]$/, "")
    else
      @res[k] = v.collect{|y|
        y=y.sub(/ [;:]$/, "")
      }
    end
  }
  @res.each{|k,v|
    if v.class == String
      v = v.strip
    else
      @res[k] = v.collect{|y|
        y = y.strip
      }
    end
  }
  if @res["isbn"].class == Array
    @res["isbn"] = @res["isbn"].collect{|x| x.scan(/[0-9]+/).first}.sort_by(&:length).reverse.first
  end
end

def show_result
  @res = {}
  @origs = {}
  @order = []
  print_thing("Title", "245a")
  print_thing("Author", "100a")
  print_thing("ISBN", "020a")
  print_thing("LCCN", "010a")
  print_thing("Publisher", "260b")
  print_thing("Date of Publication", "260c")
  print_thing("Place of Publication", "260a")
  cleanup
  @res.each{|k,v|
    @res[k] = v.join(" & ") if v.class == Array
  }
  @res
end

thing = show_result

@order.each{|x|
  puts [@origs[x],@res[x]].join(": ")
}

#puts thing.to_yaml
