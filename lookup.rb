#!/usr/bin/ruby

require 'zoom'
require 'net/http'
require 'rexml/document'
require 'yaml'

# Copied from the sample that came with zoom, I trust them :P

servers_source = [
    # Server, Username, Password
    [ 'z3950.loc.gov:7090/Voyager' ], # Library of Congress
    [ 'amicus.nlc-bnc.ca/ANY', 'akvadrako', 'aw4gliu' ], # Canada
    [ 'catnyp.nypl.org:210/INNOPAC' ], # New York Public
    [ 'z3950.copac.ac.uk:2100/COPAC' ], # United Kingdom
    [ 'z3950.btj.se:210/BURK' ], # Sweden
#    [ '195.249.206.204:210/Default' ], # DenMark -- broken?
    [ 'library.ox.ac.uk:210/ADVANCE' ], # Oxford
    [ '216.16.224.199:210/INNOPAC' ], # Cambridge
    [ 'prodorbis.library.yale.edu:7090/Voyager' ], # Yale
    [ 'zsrv.library.northwestern.edu:11090/Voyager' ]] # NorthWestern University

# only use library of congress
servers_source = [[ 'z3950.loc.gov:7090/Voyager' ]]

# Again, copied, mainly because it's so trivial.

@servers = Array.new

servers_source.each do |array|
    begin
        con = ZOOM::Connection.new()
        con.preferred_record_syntax = 'MARC21'
        con.element_set_name = 'F'
        if array[1] then
            con.user = array[1]
            con.password = array[2]
        end
        con.connect(array[0])
        @servers << con
    rescue RuntimeError
      nil
    end
end

# mine!

def find_alts(isbn)
  REXML::Document.new(Net::HTTP.new('old-xisbn.oclc.org').get("/xid/isbn/#{isbn}").body).root.elements.to_a.collect{|x| x.to_s.sub(/^<isbn>(.+)<\/isbn>$/, "\\1")}.delete_if{|x| x == isbn}.flatten
end

def find_results(isbn)
  @servers.collect{|server|
    server.search("@attr 1=7 #{isbn}").records
  }
end

def _xml_clean(thing)
  REXML::Text::unnormalize(thing.to_s).gsub(/<[^>]+>/, "").strip
end

def _xml()
  reses = REXML::XPath.match(@thing, "/record/datafield/subfield")
  reses.each{|x|
    tag = REXML::XPath.match(x, "../@tag")
    code = REXML::XPath.match(x, "@code")
    body = _xml_clean(x.to_s)
    puts [tag, code, body].join(" ")
  }
end

def show_result(result)
#  return result.xml
  @thing = REXML::Document.new(result.xml)
  _xml
end

def ret_array(thing)
  thing.collect{|x| find_results(x)}.flatten.delete_if{|x| x.nil?}.sort_by{|x| x.to_s.length}.reverse
end

arr = ret_array([ARGV[0]])
if arr.length < 1
  arr = ret_array(find_alts(ARGV[0]))
end
if arr.length == 1
  thing = arr[0]
elsif arr.length == 0
  puts "Couldn't find any records"
  exit 1
else
  thing = arr.first
end

show_result(thing)
