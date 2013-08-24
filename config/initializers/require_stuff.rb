require 'nokogiri'
require 'digest/sha1'
require 'ostruct'
require 'tempfile'
require 'gnuplot'
require 'bytes'
require 'json'
require 'ostruct'
require 'bluecloth'
require RAILS_ROOT + '/lib/fix_stupid_rails.rb'
require RAILS_ROOT + '/lib/model_modifications.rb'
require RAILS_ROOT + '/lib/ordered_hash.rb'
require RAILS_ROOT + '/vendor/prawn-labels/lib/prawn/labels.rb'
require 'csv'
require 'cgi'

module ActionView
  module Helpers
    module TextHelper
      Markdown = BlueCloth
    end
  end
end

module WillPaginate
  module ViewHelpers
    def will_paginate_with_total_results(will = nil, *opts)
      ret = will_paginate_without_total_results(will, *opts)
      if will
        ret ||= ""
        start = (will.current_page-1)*will.per_page + 1
        finish = start + will.size - 1
        if finish == 0
          return ret + "No results found"
        elsif start != finish
          return ret + "Results " + start.to_s + " - " + finish.to_s + " of " + will.total_entries.to_s
        else
          return ret + "Result " + finish.to_s + " of " + will.total_entries.to_s
        end
      end
      return ret
    end
    alias_method_chain :will_paginate, :total_results
  end
end
