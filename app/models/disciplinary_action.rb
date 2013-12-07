class DisciplinaryAction < ActiveRecord::Base
  acts_as_userstamp
  def self.cashierable
    true
  end

  def to_s
    "Contact ##{contact_id}"
  end

  has_and_belongs_to_many :disciplinary_action_areas
  belongs_to :contact
  named_scope :not_disabled, :conditions => ["disabled = 'f'"]
end
