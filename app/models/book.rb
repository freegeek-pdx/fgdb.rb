class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper
  validates_uniqueness_of :isbn
  before_validation :suck_stuff_down
  before_create :add_copy

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
    self.fields.delete_if{|x| x.field == field && x.subfield == subfield}
    self.fields << Field.new(:field => field, :subfield => subfield, :data => value)
  end

  def add_copy
    c = Copy.new(:copy_id => (self.copies.map{|x| x.copy_id} + [0]).sort.last + 1)
    self.copies << c
    return c
  end
end
