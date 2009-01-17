module LibraryModelHelper
  def self.included(base)
    {
      :author => [100, 'a'],
      :title => [245, 'a'],
      :description => [520, 'a'],
      :isbn => [20, 'a']
    }.each{|k,v|
      define_method k do
        self.[](*v)
      end
      define_method (k.to_s + "=").to_sym do |val|
        self.[]=(val, *v)
      end
    }
  end
end
