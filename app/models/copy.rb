class Copy < ActiveRecord::Base
  has_many :library_events
  belongs_to :book
  include LibraryModelHelper
  before_create :make_created_event

  named_scope :overdue, :conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND due_back < ?)", Date.today]

  # WTF?!?! my belongs_to is failing...
  def book
    Book.find_by_id(self.book_id)
  end

  def make_created_event
    self.library_events = [LibraryEvent.new({:kind => kinds[:created], :date => Time.now})]
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
    types = kinds
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

  def _days_till_due
    (last_event.due_back.to_date - Date.today).to_i
  end

  def days_till_due
    my_days = _days_till_due
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

  def _times_renewed
    y = _last_checkout_event
    library_events.select{|x| x.id > y.id}.length
  end

  def times_renewed
    x = _times_renewed
    if x > 0
      return "#{x} times"
    else
      return "never"
    end
  end

  def checked_out_at
    _last_checkout_event.date
  end

  def overdue_for
    x = _days_till_due * -1
    if x == 1
      return x.to_s + " day"
    else
      return x.to_s + " days"
    end
  end

  def _last_checkout_event
    library_events.sort_by{|x| x.date}.reverse.select{|x| x.kind == kinds[:checked_out]}.first
  end

  def contact_display
    last_event.contact_display
  end

  def last_event
    library_events.sort_by{|x| x.date}.last
  end

  def due_back
    last_event.due_back
  end

  def check_in
    library_events << LibraryEvent.new(:kind => kinds[:checked_in], :contact => last_event.contact)
  end

  def check_out(contact, due_back = nil)
    date = due_back || (Date.today + number_of_days)
    library_events << LibraryEvent.new(:kind => kinds[:checked_out], :contact => contact, :due_back => date)
  end

  def renew(due_back = nil)
    date = due_back || (last_event.due_back.to_date + number_of_days)
    library_events << LibraryEvent.new(:kind => kinds[:renewed], :contact => last_event.contact, :due_back => date)
  end

  def number_of_days
    Default[:library_due_back_days]
  end

  def kinds
    LibraryEvent.kinds
  end

  def checked_out?
    last_event.kind == kinds[:checked_out] || last_event.kind == kinds[:renewed]
  end

  def checked_in?
    !checked_out? && !lost?
  end

  def lost?
    last_event.kind == kinds[:lost]
  end

  def lose(contact)
    library_events << LibraryEvent.new(:kind => kinds[:lost], :contact => contact)
  end

  def found
    library_events << LibraryEvent.new(:kind => kinds[:found], :contact => last_event.contact)
  end
end
