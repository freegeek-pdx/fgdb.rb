class PointsTrade < ActiveRecord::Base
  belongs_to :from_contact, :class_name => "Contact"
  belongs_to :to_contact, :class_name => "Contact"

  validate :points_okay
  validates_presence_of :to_contact_id
  validates_presence_of :from_contact_id
  validates_presence_of :points

  def points_okay
    return if !(self.from_contact && self.to_contact)
    errors.add("from_contact", "has negative points") if (self.from_contact.points(self.id) - self.points) < 0
    errors.add("to_contact", "has negative points") if (self.to_contact.points(self.id) + self.points) < 0
  end
end
