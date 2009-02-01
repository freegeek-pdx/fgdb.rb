class Copy < ActiveRecord::Base
  has_many :library_events
  belongs_to :book
  include LibraryModelHelper
  before_create :make_created_event

  def make_created_event
    self.library_events = [LibraryEvent.new({:kind => LibraryEvent.kinds[:created], :date => Time.now})]
  end

  def [](field, subfield)
    self.book.[](field, subfield)
  end

  def barcode
    id
  end

  def self.find_by_barcode(*args)
    find_by_id(*args)
  end

  def status
    type = last_event.kind
    types = LibraryEvent.kinds
    if type == types[:created] || type == types[:checked_in] || type == types[:found]
      return "checked in"
    elsif type == types[:lost]
      return "lost"
    elsif type == type[:renewed] || type == type[:checked_out]
      return "checked out"
    end
  end

  def last_event
    library_events.sort_by{|x| x.date}.last
  end
end
