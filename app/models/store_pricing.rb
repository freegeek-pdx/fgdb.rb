class StorePricing < ActiveRecord::Base
  belongs_to :system
  belongs_to :gizmo_type

  validates_numericality_of :unit_price_cents, :allow_nil => false, :greater_than => 0
  validates_existence_of :gizmo_type, :allow_nil => false
  define_amount_methods_on :unit_price

  def self.find_by_barcode(inbarcode)
    inbarcode = inbarcode.to_s
    if inbarcode.match(/^p(.+)$/)
      self.find_by_id($1.to_s)
    else
      self.find_by_system_id(inbarcode.to_i)
    end
  end

  def pricing_data
    {:description => description, :gizmo_type_id => gizmo_type_id, :system_id => system_id, :unit_price => unit_price, :gizmo_count => 1}
  end

  def barcode
    return "" unless self.id
    system_id ? system_id.to_s : "p" + id.to_s
  end

  # Note: it should be updated between, no duplicates
  def self.find_by_system_id(system_id)
    self.find_all_by_system_id(system_id).sort_by(&:created_at).last
  end
end
