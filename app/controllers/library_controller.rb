class LibraryController < ApplicationController
  # check in books
  def checkin
    render :text => "not yet implemented"
  end

  # check out books
  def checkout
    render :text => "not yet implemented"
  end

  # search field to show_book and show_copy
  def search
    render :text => "not yet implemented"
  end

  # enter new books and new copies ... three options
  # * use existing book
  # * pull from library of congress
  # * manually enter
  # it should have you enter the isbn, and then go down the list, finding the first possiblility, and making you use that. should also consider alternates.
  def cataloging
    render :text => "not yet implemented"
  end

  # list of copies that are overdue
  def overdue
    render :text => "not yet implemented"
  end

  # shows information, list of copies, add new copy button
  def show_book
    render :text => "not yet implemented"
  end

  # link to labels, shows history, has a checkout button
  def show_copy
    render :text => "not yet implemented"
  end

  # takes a list of copy ids, linked from search maybe? dunno how to get there yet..
  def label
    render :text => "not yet implemented"
  end
end
