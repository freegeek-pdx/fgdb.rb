class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper
  validates_uniqueness_of :isbn
  before_validation :suck_stuff_down
  before_create :add_copy

  # TODO: this breaks stuff. the isbn that gets sucked down is a sucky
  # prepresentation of array (because there's more than one), which
  # don't work right with find_by_isbn. I should just rewrite
  # find_by_isbn to use fields. how will this affect conditions?  I
  # think I'll just remove the whole sucking down stuff, tho that
  # scares me wrt search. I suppose that it will still work with SQL,
  # just more complex. NOTE: it is stored correctly in the fields table.
  def suck_stuff_down
    for i in [:author, :isbn, :title, :description]
      eval("write_attribute(:#{i.to_s}, #{i.to_s})")
    end
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
