class System < ActiveRecord::Base
  belongs_to :contract
  attr_protected :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  attr_readonly :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  validates_presence_of :vendor, :serial_number, :model
  validates_existence_of :contract
  has_many :spec_sheets

  def validate
    if self.contract.nil?
      errors.add("contract_id", "contract is not valid")
    end
  end
end
