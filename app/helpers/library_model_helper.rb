module LibraryModelHelper
  def self.included(base)
    MarcHelper.marc_aliases.each{|k,v|
      define_method k do
        self.[](*v)
      end
      define_method (k.to_s + "=").to_sym do |val|
        self.[]=(val, *v)
      end
    }
  end
end

module MarcHelper
  # may end up being used in conditions and such
  def self.marc_aliases
    {
      :author => [100, 'a'],
      :title => [245, 'a'],
      :description => [520, 'a'],
      :isbn => [20, 'a']
    }
  end
end
