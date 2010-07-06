class Copy < ActiveRecord::Base
  has_many :library_events
  belongs_to :book
  include LibraryModelHelper
  before_create :make_created_event

  named_scope :overdue, lambda {{ :conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND due_back < ?)", Date.today] }}
  named_scope :overdue_for_contact, lambda {|cid| { :conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND due_back < ? AND contact_id = ?)", Date.today, cid] }}
  named_scope :checked_out_to, lambda {|cid| {:conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND kind IN (?) AND contact_id = ?)", LibraryEvent.these_kinds(:checked_out, :renewed), cid]}}
  named_scope :lost_by, lambda {|cid| {:conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND kind = ? AND contact_id = ?)", LibraryEvent.kinds[:lost], cid]}}
  named_scope :in_library, :conditions => ["id in (SELECT copy_id FROM library_events WHERE id IN (SELECT max(id) FROM library_events GROUP BY copy_id) AND kind IN (?))", LibraryEvent.these_kinds(:recreated, :created, :checked_in)]

  # WTF?!?! my belongs_to is failing...
  def book
    Book.find_by_id(self.book_id)
  end

  def long_description
    sprintf("%s (Copy #%s, Barcode #%s)", self.book.title, self.copy_id, self.barcode)
  end

  def make_created_event
    self.library_events = [LibraryEvent.new({:kind => kinds[:created], :date => Time.now})]
  end

  def [](field, subfield)
    self.book.[](field, subfield)
  end

  def barcode
    return sprintf("%6d", id).gsub(" ", "0") if id.to_s.length < 6
    return id.to_s # else
  end

  def self.find_by_barcode(*args)
    find_by_id(*args)
  end

  def status
    type = last_event.kind
    types = kinds
    if type == types[:created] || type == types[:checked_in] || type == types[:found] || type == types[:recreated]
      return "checked in"
    elsif type == types[:lost]
      return "lost"
    elsif type == types[:removed]
      return "removed"
    elsif type == types[:renewed] || type == types[:checked_out]
      return "checked out"
    end
  end

  def long_status
    if status == "checked out"
      return "checked out to " + contact_display + " (#{days_till_due})"
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
    last_event.contact_display_with_link
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

  def lost
    library_events << LibraryEvent.new(:kind => kinds[:lost], :contact => [kinds[:checked_out], kinds[:renewed]].include?(last_event.kind) ? last_event.contact : nil)
  end

  def found
    library_events << LibraryEvent.new(:kind => kinds[:found], :contact => last_event.contact)
  end

  def remove
    library_events << LibraryEvent.new(:kind => kinds[:removed])
  end

  def recreate
    library_events << LibraryEvent.new(:kind => kinds[:recreated])
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
    Default["library_due_back_days"].to_i
  end

  def kinds
    LibraryEvent.kinds
  end

  def checked_out?
    self.status == "checked out"
  end

  def checked_in?
    self.status == "checked in"
  end

  def lost?
    self.status == "lost"
  end

  def removed?
    self.status == "removed"
  end

  def lose(contact)
    library_events << LibraryEvent.new(:kind => kinds[:lost], :contact => contact)
  end

  def found
    library_events << LibraryEvent.new(:kind => kinds[:found], :contact => last_event.contact)
  end
end
