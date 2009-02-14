class OrderedHash
  def initialize(*args)
    @hash = {}
    @arr = []
    process(*args)
  end

  def process(*args)
    while args.length >= 2
      add(args[0], args[1])
      args.delete_at(0)
      args.delete_at(0)
    end
  end

  def add(key, val)
    @arr.delete_if{|x| x == key}
    @hash[key] = val
    @arr << key
    self
  end

  def a(key, val)
    add(key, val)
  end

  def self.n(*args)
    OrderedHash.new(*args)
  end

  def [](key)
    @hash[key]
  end

  def []=(key, val)
    add(key, val)
  end

  def each
    @arr.each{|x|
      yield(x, @hash[x])
    }
    nil
  end

  def keys
    @arr
  end

  def values
    @arr.map{|x|
      @hash[x]
    }
  end

  def length
    @arr.length
  end
end

OH = OrderedHash
