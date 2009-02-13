require 'net/http'

class ISBN
  def self.new(isbn)
    str = isbn.upcase.gsub(/[^X0-9]/, "")
    if str.length == 10
      thing = ISBN10.new(str)
    elsif str.length == 13
      thing = ISBN13.new(str)
    end
    return nil if thing.nil? or !thing.valid_format?
    return thing
  end
end

class ISBNBase
  def initialize(isbn)
    @isbn = isbn
  end

  def as_purdy
    str = ""
    i = 0
    arr = @isbn.scan(/./).reverse
    while (x = arr.pop)
      i += 1
      str += x
      str += "-" if dashes.include?(i) && arr.length > 0
    end
    str
  end

  def as_normalized
    @isbn
  end

  def to_isbn10
    if @isbn.match(/^978/)
      return ISBN.new(@isbn.sub(/^978/, ""))
    else
      return nil
    end
  end

  def to_isbn13
    return ISBN.new("978" + @isbn)
  end

  def valid_format?
    @isbn.match(/^\d{0,3}\d{9}[\dX]{1}$/)
  end

  def isbn
    @isbn
  end

  def to_other
    if is_isbn10?
      return to_isbn13
    elsif is_isbn13?
      return to_isbn10
    else
      return nil
    end
  end

  def is_isbn10?
    false
  end

  def is_isbn13?
    false
  end

  def find_similar
    Net::HTTP.get("old-xisbn.oclc.org", "/xid/isbn/#{as_normalized}").split("\n").select{|x| x.match("^<isbn>.+</isbn>$")}.map{|x| x.gsub(/<\/?isbn>/, "")}.map{|x| ISBN.new(x)}.delete_if{|x| x.nil?}
  end
end

class ISBN10 < ISBNBase
  def dashes
    [1,4,9]
  end

  def to_isbn10
    self
  end

  def is_isbn10?
    true
  end
end

class ISBN13 < ISBNBase
  def dashes
    [3,4,7,12]
  end

  def to_isbn13
    self
  end

  def is_isbn13?
    true
  end
end

class ISBNs
  def initialize(*isbns)
    @isbns = isbns.map{|x| x.split(/[, ]/)}.flatten.map{|x| ISBN.new(x)}.delete_if{|x| x.nil?}
  end

  def add_alternates
    @isbns = @isbns.map{|x| [x, x.to_other]}.flatten.delete_if{|x| x.nil?}
    return self
  end

  def add_similar
    @isbns = @isbns.map{|x| [x, x.find_similar]}.flatten.delete_if{|x| x.nil?}
    return self
  end

  def isbns
    @isbns
  end

  def to_s
    to_purdy
  end

  def to_a
    to_normalized
  end

  def to_purdy
    @isbns.map{|x| x.as_purdy}.uniq.join(", ")
  end

  def to_normalized
    @isbns.map{|x| x.as_normalized}.uniq
  end
end
