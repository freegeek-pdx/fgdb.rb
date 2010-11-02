class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper
  before_create :add_copy
  acts_like_xapian :a => 1
  validate :uniq_isbn

  def uniq_isbn
    if self.internal_isbn.length == 0
      errors.add('isbn', 'needs to be entered')
      return
    end
    books = find_books_with_my_isbn
    errors.add('isbn', 'is not unique') if books != [self.id] && books != []
  end

  def find_books_with_my_isbn
    isbns = self.internal_isbn.split(" ")
    return [self.id] if isbns.nil? or isbns.empty? or isbns.length == 0 or isbns[0].length == 0
    isbns_conditions = isbns.map{|this_isbn| "data = '#{this_isbn}'"}.join(" OR ")
    sql = "SELECT book_id FROM fields WHERE field = 20 AND subfield = 'a' AND (#{isbns_conditions})"
    Book.connection.execute(sql).to_a.map{|x| x["book_id"].to_i}.uniq
  end

  def self.find_by_isbn(thing)
    a, b = MarcHelper.marc_aliases[:isbn]
    res = [thing].flatten.collect{|x|
      Field.find(:all, :conditions => {:field => a, :subfield => b, :data => x.to_s})
    }.delete_if{|x| x.nil?}.flatten.map{|x| x.book}.uniq
    return nil if res.length == 0
    return res[0] if res.length == 1
    return res
  end

  def [](field, subfield)
    arr = self.fields.select{|x| x.field == field && x.subfield == subfield}.collect{|x| x.data}
    return nil if arr.length == 0
    return arr[0] if arr.length == 1
    return arr
  end

  def []=(value, field, subfield)
    values = [value].flatten
    self.fields.delete_if{|x| x.field == field && x.subfield == subfield}
    values.each{|val|
      self.fields << Field.new(:field => field, :subfield => subfield, :data => val)
    }
  end

  def add_copy
    c = Copy.new(:copy_id => (self.copies.map{|x| x.copy_id} + [0]).sort.last + 1)
    self.copies << c
    return c
  end
end