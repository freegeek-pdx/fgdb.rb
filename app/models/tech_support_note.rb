class TechSupportNote < ActiveRecord::Base
  belongs_to :contact
  acts_as_userstamp

  validates_uniqueness_of :contact_id
  validates_existence_of :contact
  validates_presence_of :contact_id
  validates_presence_of :notes

  def self.contacts_with_notes(name)
    Contact.search(name, {:limit => 25}).select{|x| x.tech_support_note}
  end

  def self.contacts_without_notes(name)
    Contact.search(name, {:limit => 25}).select{|x| !x.tech_support_note}
  end
end
