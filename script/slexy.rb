#!/usr/bin/ruby

require 'net/http'
require 'cgi'
require 'uri'

module Multipart
  # From: http://kfahlgren.com/code/multipart.rb
  class Param
    attr_accessor :k, :v
    def initialize( k, v )
      @k = k
      @v = v
    end

    def to_multipart
      return "Content-Disposition: form-data; name=\"#{CGI::escape k}\"\r\n\r\n#{v}\r\n"
    end
  end
  class FileParam
    attr_accessor :k, :filename, :content
    def initialize( k, filename, content )
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      # Don't escape mine
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: application/xml\r\n\r\n" + content + "\r\n"
    end
  end
  class MultipartPost
    BOUNDARY = 'tarsiers-rule0000'
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " ", "User-Agent"=>"Slexy.rb"}

    def prepare_query (params)
      fp = []
      params.each {|k,v|
        if v.respond_to?(:read)
          fp.push(FileParam.new(k, v.path, v.read))
        else
          fp.push(Param.new(k,v))
        end
      }
      query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end  
end

def fetch(url, limit = 10)
  return nil if limit == 0

  response = Net::HTTP.get_response(URI.parse(url))
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  else
    nil
  end
end

TIMEOUT_SECONDS = 30
def post_form(url, query, headers)
  limit=10
  Net::HTTP.start(url.host, url.port) { |con|
    con.read_timeout = TIMEOUT_SECONDS
    begin
      response = con.post(url.path, query, headers)
        case response
        when Net::HTTPSuccess     then return response
        when Net::HTTPRedirection then return fetch(response['location'], limit - 1)
        else
          nil
        end
    rescue => e
      nil
    end
  }
end

string = ""

while((line = STDIN.gets))
   string += line
end

data = {
  "raw_paste" => string,
  "language" => "text",
  "submit" => "Submit Paste"
}

url = "http://slexy.org/index.php/submit"
uri = URI.parse(url)

mp = Multipart::MultipartPost.new
query, headers = mp.prepare_query(data)
response = post_form(uri, query, headers)
puts response.body.match(/<a href="\/raw\/.*">View raw paste<\/a>/)[0].sub(/<a href="\/raw\//, "http://slexy.org/view/").sub(/">View raw paste<\/a>/, "")
