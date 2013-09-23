class System < ActiveRecord::Base
  belongs_to :contract
  attr_protected :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  attr_readonly :mobo_vendor, :system_vendor, :mobo_serial_number, :system_serial_number, :mobo_model, :system_model, :vendor, :serial_number, :model
  validates_presence_of :vendor, :serial_number, :model
  validates_existence_of :contract
  has_many :spec_sheets
  has_many :notes
  has_many :gizmo_events

  def last_spec_sheet
    self.spec_sheets.sort_by(&:created_at).last
  end

  def previous
    self.class.find(previous_id) if previous_id
  end

  def next
    self.class.find_by_previous_id(self.id)
  end

  def last_gizmo_event
    self.all_instances.map{|x| x.gizmo_events}.flatten.select{|x| (!x.sale_id.nil?) or (!x.disbursement_id.nil?) }.sort_by(&:occurred_at).last
  end

  def tech_support_source
    gt = last_gizmo_event
    if gt
      if gt.sale_id.nil?
        dtd = gt.disbursement.disbursement_type.description
        if ["Adoption", "Build", "Hardware Grants"].include?(dtd)
          return dtd.singularize
        else
          return nil
        end
      else
        return "Store"
      end
    else
      return nil
    end
  end

  def all_instances
    [self.all_next, self, self.all_previous].flatten
  end

  def all_next
    return self.next ? [self.next.all_next, self.next] : []
  end

  def all_previous
    return self.previous ? [self.previous, self.previous.all_previous] : []
  end

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

  def gone?
    self.gizmo_events.length > 0
  end
end
