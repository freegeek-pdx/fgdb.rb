class LibraryController < ApplicationController
  layout :with_sidebar
  before_filter :authorized_only

  def authorized_only
    requires_role(:LIBRARIAN)
  end

  def lookup
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
  def findit(isbn)
    @book = Book.find_by_isbn(isbn)
    if @book
      @method = "book"
    else
      @marc = lookup_loc(isbn)
      if @marc
        if @marc.isbn != isbn
          @book = Book.find_by_isbn(@marc.isbn)
        end
        if @book
          @method = "book"
          @marc = nil # just in case
        else
          @method = "marc"
        end
      else
        @method = "manual"
      end
    end
  end

  public

  def redirect_to_show_book
    redirect_to :action => :show_book, :id => params[:open_struct][:book_id]
  end

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
    findit(isbn)
    if @method == "manual"
      @book = Book.new
    end
    render :update do |page|
      case @method
        when "manual" then page.replace_html "main_form", :partial => "main_form"
        when "book" then page.replace_html "main_form", :partial => "show_book", :object => @book
        when "marc" then page.replace_html "main_form", :partial => "show_book", :object => @marc
      end
      if @method != "manual"
        page['initial_form'].hide
      else
        page << "$('book_isbn').value = \"#{isbn}\";"
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
      add_to_session_labels(b.copies.first.id)
      redirect_to :action => "show_book", :id => b.id
    end
  end

  def create
    b = Book.new(params[:book])
    if !b.save!
      render :text => "Failed to save: #{b.errors.to_s}"
    else
      add_to_session_labels(b.copies.first.id)
      redirect_to :action => "show_book", :id => b.id
    end
  end

  # list of copies that are overdue
  def overdue
    render :text => "not yet implemented"
  end

  # shows information, list of copies, add new copy button
  def show_book
    @book = Book.find(params[:id])
  end

  # link to labels, shows history, has a checkout button
  def show_copy
    id = (params[:copy] ? params[:copy][:id] : params[:copy_id])
    @c = Copy.find(id)
  end

  # takes a list of copy ids, linked from search maybe? dunno how to get there yet..
  def labels
    render :text => "printing teh labels: #{list_labels_in_session.join(", ")}"
    remove_from_session_labels(list_labels_in_session)
  end

  def add_to_labels
    add_to_session_labels(params[:id])
    redirect_to :action => "show_book", :id => Copy.find_by_id(params[:id]).book_id
  end

  # adds a copy for that book
  def add_copy
    add_to_session_labels(Book.find_by_id(params[:book_id]).add_copy.id)
    redirect_to :action => "show_book", :id => params[:book_id]
  end
end
