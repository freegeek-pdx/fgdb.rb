class PointsTrade < ActiveRecord::Base
  acts_as_userstamp

  belongs_to :from_contact, :class_name => "Contact"
  belongs_to :to_contact, :class_name => "Contact"

  validate :points_okay
  validates_presence_of :to_contact_id
  validates_presence_of :from_contact_id
  validates_presence_of :points
  validates_existence_of :to_contact
  validates_existence_of :from_contact

  def self.allow_shared
    true
  end

  def points_okay
    return if !(self.from_contact && self.to_contact)
    errors.add("from_contact", "has negative points") if self.points && (self.from_contact.points(self.id) - self.points) < 0
    errors.add("to_contact", "has negative points") if self.points && (self.to_contact.points(self.id) + self.points) < 0
  end
end
