module LibraryModelHelper
  def self.included(base)
    MarcHelper.marc_aliases.each{|k,v|
      define_method k do
        self.m(*v)
      end
      define_method (k.to_s + "=").to_sym do |val|
        self.me(val, *v)
      end
    }
  end

  def me(*a)
    self.[]=(*a[0..2])
  end

  def m(*a)
    str = ""
    while a.length > 1
      b = a[0]
      a.delete_at(0)
      c = a[0]
      a.delete_at(0)
      t = self.[](b,c)
      if t
        str += " " if str.length > 0
        str += t
      end
    end
    return str
  end
end

module MarcHelper
  # may end up being used in conditions and such
  def self.marc_aliases
    {
      :author => [100, 'a'],
      :title => [245, 'a'],
      :description => [520, 'a'],
      :isbn => [20, 'a'],
      :call_number => [50, 'a', 50, 'b']
    }
  end

  def self.show_list
    [:isbn, :title, :author, :description, :call_number]
  end
end
