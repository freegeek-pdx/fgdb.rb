class Type < ActiveRecord::Base
  named_scope :usable
  has_and_belongs_to_many :pricing_types
  belongs_to :gizmo_type

  def to_s
    description
  end
end
