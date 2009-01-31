class Copy < ActiveRecord::Base
  has_many :library_events
  belongs_to :book
  include LibraryModelHelper

  def [](field, subfield)
    self.book.[](field, subfield)
  end

  def barcode
    id
  end

  def status
    "blah"
  end
end
