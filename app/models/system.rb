class System < ActiveRecord::Base
  belongs_to :contract
  attr_protected :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  attr_readonly :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  validates_presence_of :vendor, :serial_number, :model
  validates_existence_of :contract
  has_many :spec_sheets
  has_many :notes
  has_many :gizmo_events

  def covered_s
    self.covered.to_s
  end

  def covered_s=(val)
    self.covered = eval(val)
  end

  def validate
    if self.contract.nil?
      errors.add("contract_id", "contract is not valid")
    end
  end
end
