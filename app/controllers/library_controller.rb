class LibraryController < ApplicationController
  layout :with_sidebar
  before_filter :authorized_only

  def authorized_only
    requires_role(:LIBRARIAN)
  end

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
  end

  helper :zoom
  include ZoomHelper

  private
  def findit(isbns)
    isbns.collect!{|x| x.to_i}
    @books = Book.find_all_by_isbn(isbns)
    if @books.length == 1
      @book = @books[0]
      @method = "book"
    else
      @marc = lookup_loc(isbns)
      if @marc
        @method = "marc"
      else
        @method = "manual"
      end
    end
  end

  public

  # ajaxy magic ... wow!
  def cataloging_update
    # try to find existing book
    isbn = params[:open_struct][:isbn]
    if isbn.nil? || isbn.blank? || (isbn.length != 10 && isbn.length != 13)
      render :update do |page|
        page << "alert('Invalid ISBN');"
        page.hide loading_indicator_id("library_cataloging")
      end
      return
    end
    findit([isbn])
    if @method == "manual"
      isbns = list_alternates(isbn.to_i)
      findit(isbns)
    end
    if @method == "manual"
      @isbn = isbn
    end
    render :update do |page|
      case @method
        when "manual" then page.replace_html "main_form", :partial => "main_form"
        when "book" then page.replace_html "main_form", :partial => "show_book"
        when "marc" then page.replace_html "main_form", :partial => "show_book"
      end
      if @method != "manual"
        page['initial_form'].hide
      end
      page.hide loading_indicator_id("library_cataloging")
    end
  end

  def create_from_marc
    @marc = Marc.new(params[:open_struct][:marc])
    b = Book.new
    b.fields = @marc.to_fields
    if !b.save!
      render :text => "Failed to save: #{b.errors.to_s}"
    else
      redirect_to :action => "show_book", :id => b.id
    end
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
