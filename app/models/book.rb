class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper

  def [](field, subfield)
    arr = self.fields.select{|x| x.field == field && x.subfield == subfield}.collect{|x| x.data}
    return nil if arr.length == 0
    return arr[0] if arr.length == 1
    return arr
  end
end
