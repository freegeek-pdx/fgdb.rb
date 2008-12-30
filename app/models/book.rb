class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper
  validates_uniqueness_of :isbn
  before_save :suck_stuff_down

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
end
