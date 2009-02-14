class LibraryController < ApplicationController
  layout :with_sidebar
  before_filter :authorized_only, :except => [:show_copy, :show_book, :search, :search_results]
  helper :library_labels
  include LibraryLabelsHelper

  def authorized_only
    requires_role(:LIBRARIAN)
  end

  def lookup
  end

  # check in books
  def checkin
    Copy.find_by_id(params[:copy_id]).check_in
    redirect_to :action => "show_copy", :id => params[:copy_id]
  end

  # renew books
  def renew
    Copy.find_by_id(params[:copy_id]).renew
    redirect_to :action => "show_copy", :id => params[:copy_id]
  end

  # check out books
  def checkout
    Copy.find_by_id(params[:checkout][:copy_id]).check_out(Contact.find_by_id(params[:contact][:id]))
    redirect_to :action => "show_copy", :id => params[:checkout][:copy_id]
  end

  # search field to show_book and show_copy
  def search
  end

  def search_results
    @books = Book.search(params[:search][:query]).paginate({:page => params[:page]})
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
        @method = "marc"
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
    isbns_object = ISBNs.new(params[:open_struct][:isbn]).add_alternates
    isbn = isbns_object.to_a
    if isbn.length == 0
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
        page << "$('book_isbn').value = \"#{isbns_object.to_s}\";"
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
    params[:book][:isbn] = ISBNs.new(params[:book][:isbn]).to_a
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
    @copies = Copy.overdue.paginate :page => params[:page]
  end

  # shows information, list of copies, add new copy button
  def show_book
    @book = Book.find(params[:id])
  end

  # link to labels, shows history, has a checkout button
  def show_copy
    # weee!!! :p
    if params[:copy] && params[:copy][:id]
      id = params[:copy][:id]
    elsif params[:copy_id]
      id = params[:copy_id]
    else
      id = params[:id]
    end
    @c = Copy.find(id)
  end

  # takes a list of copy ids, linked from search maybe? dunno how to get there yet..
  def labels
    cols, rows = get_dimensions
    recommended_pages = (list_labels_in_session.length.to_f / (cols.to_i * rows.to_i)).ceil
    res = gen_pdf(list_labels_in_session, recommended_pages, []) # 3rd arg is a list of label positions to skip
    remove_from_session_labels(list_labels_in_session)
    redirect_to :action => "show_pdf", :id => res
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

  def show_pdf
    file = File.join(RAILS_ROOT, "tmp", "tmp", params[:id].sub("$", "."))
    respond_to do |format|
      format.pdf { render :text => File.read(file) }
    end
    File.unlink(file)
  end
end
