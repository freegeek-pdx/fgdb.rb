class ContactMethod < ActiveRecord::Base
  belongs_to :contact_method_type
  belongs_to :contact
  validates_associated :contact, :unless => :new_contact
  validates_associated :contact_method_type
  validates_presence_of :contact, :unless => :new_contact
  validates_presence_of :contact_method_type

  def new_contact
    true # self.contact && self.contact.id.nil? # FIXME
  end

  def validate
    errors.add('value', 'should not contain HTML, please disable Google Voice and other annoying browser plugins') if self.value && self.value.match(/<span/)
  end

  def to_s
    desc = value
    desc += ", " + self.details if self.details && self.details.length > 0
    return desc
  end

  def display
    desc = contact_method_type.description
    desc += ", " + self.details if self.details && self.details.length > 0
    "%s (%s)" % [value, desc]
  end
end
