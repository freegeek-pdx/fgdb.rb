class TechSupportNotesController < ApplicationController
  protected
  def get_required_privileges
    a = super
    a << {:privileges => ['staff'], :except => ['find_footnotes']}
    a << {:privileges => ['techsupport_workorders'], :only => ['find_footnotes']}
    a
  end
  public

  # TODO: dynamically too later
  def find_notes
    name = params[:id]
    render :update do |page|
      page.replace_html "extra_form", :partial => "ts_notes", :locals => {:name => name}
      page.hide loading_indicator_id("ts_customer_search")
    end
  end

  def add_note
    @name = params[:id]
    @contacts = TechSupportNote.contacts_without_notes(@name)
    render :update do |page|
      page.replace_html "ts-note-new", :partial => "new_note"
      page.hide "ts-notes-found"
      page.hide loading_indicator_id("ts-new-note")
    end
  end

  def new_note_form
    name = params[:name]
    cid = params[:id]
    if cid
      @contact = Contact.find(cid)
    else
      @contact = _create_contact(name)
    end
    render :update do |page|
      page.replace_html "ts-note-new", :partial => "note_form"
      page.hide loading_indicator_id("ts-new-note")
    end
  end

  def save_note
    note_t = params[:notes]
    name = params[:name]
    cid = params[:id]
    if cid
      @contact = Contact.find(cid)
    else
      @contact = _create_contact(name)
      @contact.save
    end
    note = @contact.tech_support_note
    if note
      note.notes = note_t
      note.save
    else
      note = @contact.create_tech_support_note(:notes => note_t)
      note.save
    end
    render :update do |page|
      page.replace "note-form-#{cid}", :partial => "tech_support_notes/note", :locals => {:contact => @contact}
    end
  end

  private
  def _create_contact(name)
    contact = Contact.new
    surname = name.split(" ")
    firstname = surname.shift
    surname = surname.join(" ")
    contact.first_name = firstname
    contact.surname = surname
    return contact
  end
  public

  def edit_note
    cid = params[:id]
    @contact = Contact.find(cid)
    @note = @contact.tech_support_note

    render :update do |page|
      page.replace "ts-note-#{@contact.id}", :partial => "note_form"
    end
  end
end
