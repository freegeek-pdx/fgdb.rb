module LibraryModelHelper
  def self.included(base)
    MarcHelper.marc_aliases.each{|k,v|
      define_method "internal_" + k.to_s do
        self.m(*v)
      end
      define_method k do
        begin
          eval("self.#{k}_to_s")
        rescue NameError
          eval("self.internal_#{k}")
        end
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
    arr = []
    while a.length > 1
      b = a[0]
      a.delete_at(0)
      c = a[0]
      a.delete_at(0)
      t = self.[](b,c)
      if t
        arr << t
      end
    end
    arr.flatten!
    return arr.join(" ")
  end

  def isbn_to_s
    ISBNs.new(internal_isbn).to_s
  end

  def isbn_to_a
    ISBNs.new(internal_isbn).to_a
  end
end

module MarcHelper
  # may end up being used in conditions and such
  def self.marc_aliases
    {
      :author => [100, 'a'],
      :title => [245, 'a'],
      :isbn => [20, 'a'],
      :call_number => [50, 'a', 50, 'b']
    }
  end

  def self.show_list
    [:isbn, :title, :author, :call_number]
  end
end
