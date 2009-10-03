class Default < ActiveRecord::Base
  class << self
    def is_pdx
      Default["is-pdx"] == "true"
    end
    def [](name)
      return find_by_name(name).value
    rescue
      return nil
    end
    def []=(name,__value)
      d = find_by_name(name)
      d = Default.new if d.nil?
      d.name = name
      d.value = __value
      d.save!
      return d
    end
    def keys
      find(:all).map(&:name).uniq
    end
  end
end
