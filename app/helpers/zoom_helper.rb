module ZoomHelper
  class Marc
    include LibraryModelHelper

    def initialize(thing = nil)
      super()
      if thing
        self.data=(thing)
      end
    end

    def to_fields
      fields = []
      @data.each{|x,h|
        h.each{|y,a|
          [a].flatten.each{|z|
            if z.is_a?(Array)
              z.each{|a|
                fields << Field.new(:field => x, :subfield => y, :data => a)
              }
            else
              fields << Field.new(:field => x, :subfield => y, :data => z)
            end
          }
        }
      }
      fields
    end

    def data=(data)
      @data = {}
      @orig_data = data
      if data.class != String
        thing = data.xml
      else
        thing = data
      end
      data = show_res(thing)
      data.each{|a|
        x, y, z = a
        x = x.to_i
        @data[x] ||= {}
        if !@data[x][y]
          @data[x][y] = z
        else
          if @data[x][y].class != Array
            temp = @data[x][y]
            @data[x][y] = [temp]
          end
          @data[x][y] << z
        end
      }
    end

    def to_s
      @orig_data.xml # I guess..
    end

    def [](a,b)
      if @data[a]
        return @data[a][b]
       else
         return nil
      end
    end

    private
    def show_res(res)
      thing = REXML::Document.new(res)
      ret = []
      reses = REXML::XPath.match(thing, "/record/datafield/subfield")
      reses.each{|x|
        tag = REXML::XPath.match(x, "../@tag")
        code = REXML::XPath.match(x, "@code")
        body = _xml_clean(x.to_s)
        ret << [tag.to_s, code.to_s, body]
      }
      return ret
    end

    def _xml_clean(thing)
      REXML::Text::unnormalize(thing.to_s).gsub(/<[^>]+>/, "").strip
    end
  end

  class Zoomer
    def initialize
      init_marc
    end

    private

    def init_marc
      @@init ||= false
      if @@init
        return
      end

      @@servers = Array.new

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
          @@servers << con
        rescue RuntimeError
          nil
        end
        @@init = true
      end
    end

    def other_servers_source # not used
      [
       # Server, Username, Password
       [ 'z3950.loc.gov:7090/Voyager' ], # Library of Congress
       [ 'amicus.nlc-bnc.ca/ANY', 'akvadrako', 'aw4gliu' ], # Canada
       [ 'catnyp.nypl.org:210/INNOPAC' ], # New York Public
       [ 'z3950.copac.ac.uk:2100/COPAC' ], # United Kingdom
       [ 'z3950.btj.se:210/BURK' ], # Sweden
       # [ '195.249.206.204:210/Default' ], # DenMark -- broken?
       [ 'library.ox.ac.uk:210/ADVANCE' ], # Oxford
       [ '216.16.224.199:210/INNOPAC' ], # Cambridge
       [ 'prodorbis.library.yale.edu:7090/Voyager' ], # Yale
       [ 'zsrv.library.northwestern.edu:11090/Voyager' ]] # NorthWestern University
    end

    def servers_source
      [[ 'z3950.loc.gov:7090/Voyager' ]]
    end

    def lookup_thing(isbns)
      res = isbns.collect{|x|
        @@servers.collect{|server|
          server.search("@attr 1=7 #{x}").records
        }
      }.flatten.delete_if{|x| x.nil?}.sort_by{|x| x.to_s.length}.reverse
      return res[0] if res.length == 1
      return res.first if res.length > 1
      return nil if res.length == 0
    end

    public

    def lookup_loc(isbns)
      res = lookup_thing([isbns].flatten)
      return res if res.nil?
      m = Marc.new
      m.data = res
      return m
    end

    def list_alternates_fail(isbn) # FAIL. limits to 500 requests a day. don't think that's a good idea.
      REXML::Document.new(Net::HTTP.new('old-xisbn.oclc.org').get("/xid/isbn/#{isbn}").body).root.elements.to_a.collect{|x| x.to_s.sub(/^<isbn>(.+)<\/isbn>$/, "\\1")}.delete_if{|x| x == isbn}.flatten
    end
  end

  def lookup_loc(isbns)
    Zoomer.new.lookup_loc(isbns)
  end
end