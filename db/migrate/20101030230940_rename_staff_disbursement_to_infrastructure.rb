class RenameStaffDisbursementToInfrastructure < ActiveRecord::Migration
  def self.up
    p = DisbursementType.find_by_name("staff")
    if Default.is_pdx && p
      p.name = "infrastructure"
      p.description = "Infrastructure"
      p.save!
    end
  end

  def self.down
  end
end
