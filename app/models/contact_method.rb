class ContactMethod < ActiveRecord::Base
  belongs_to :contact_method_type
  belongs_to :contact
  validates_associated :contact, :contact_method_type
  validates_presence_of :contact, :contact_method_type

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
