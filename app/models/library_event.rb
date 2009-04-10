class LibraryEvent < ActiveRecord::Base
  belongs_to :copy
  belongs_to :contact
  before_create :set_date

  acts_as_userstamp

  def set_date
    self.date = Time.now
  end

  def self.these_kinds(*names)
    names.collect{|x| LibraryEvent.kinds[x]}
  end

  def self.kinds
    {
      :created => 1,
      :checked_out => 2,
      :renewed => 3,
      :checked_in => 4,
      :lost => 5,
      :found => 6,
    }
  end

  def kind_to_s
    LibraryEvent.kinds.select{|k,v| v == self.kind}[0][0].to_s.titleize
  end

  def contact_display
    setup_user
    if contact
      if has_role?("LIBRARIAN", "CONTACT_MANAGER")
        contact.display_name
      else
        "#" + contact.id.to_s
      end
    else
      ""
    end
  end

  include ApplicationHelper

  def librarian
    Contact.find(created_by)
  end

  def librarian_display
    setup_user
    if has_role?("LIBRARIAN", "CONTACT_MANAGER")
      librarian.display_name
    else
      "#" + librarian.id.to_s
    end
  end

  # a hack
  def setup_user
    @current_user ||= Thread.current['user']
  end
end
