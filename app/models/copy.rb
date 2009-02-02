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
    elsif type == types[:renewed] || type == types[:checked_out]
      return "checked out"
    end
  end

  def long_status
    if status == "checked out"
      return "checked out by " + contact_display + " (#{days_till_due})"
    else
      return status
    end
  end

  def due_back
    last_event.due_back
  end

  def days_till_due
    my_days = (last_event.due_back.to_date - Date.today).to_i
    if my_days > 1
      return "due back in " + my_days.to_s + " days"
    elsif my_days == 1
      return "due back tomorrow"
    elsif my_days == 0
      return "due back today"
    else
      return "overdue"
    end
  end

  def contact_display
    "#" + last_event.contact.id.to_s
  end

  def last_event
    library_events.sort_by{|x| x.date}.last
  end

  def due_back
    last_event.due_back
  end

  def check_in
    library_events << LibraryEvent.new(:kind => LibraryEvent.kinds[:checked_in], :contact => last_event.contact)
  end

  def check_out(contact, due_back = nil)
    date = due_back || (Date.today + number_of_days)
    library_events << LibraryEvent.new(:kind => LibraryEvent.kinds[:checked_out], :contact => contact, :due_back => date)
  end

  def renew(due_back = nil)
    date = due_back || (last_event.date + number_of_days)
    library_events << LibraryEvent.new(:kind => LibraryEvent.kinds[:renewed], :contact => last_event.contact, :due_back => date)
  end

  def number_of_days
    # TODO: add this field in a migration
    Default[:library_due_back_days] || 14
  end

  def kinds
    LibraryEvent.kinds
  end

  def lost?
    last_event.kind == kinds[:lost]
  end

  def lose(contact)
    library_events << LibraryEvent.new(:kind => LibraryEvent.kinds[:lost], :contact => contact)
  end

  def found
    library_events << LibraryEvent.new(:kind => LibraryEvent.kinds[:found], :contact => last_event.contact)
  end
end
