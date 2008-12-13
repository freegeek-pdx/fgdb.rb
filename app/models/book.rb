class Book < ActiveRecord::Base
  has_many :fields
  has_many :copies
  include LibraryModelHelper

  def [](field, subfield)
    return self.fields.select{|x| x.field == field && x.subfield == subfield}.collect{|x| x.data}
  end
end
