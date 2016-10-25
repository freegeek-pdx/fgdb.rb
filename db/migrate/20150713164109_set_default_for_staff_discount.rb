class SetDefaultForStaffDiscount < ActiveRecord::Migration
  def self.up
    Default["discount_percentage_id_for_staff_discount"] = DiscountPercentage.find_by_percentage(30).id
    dn = DiscountName.find_by_description("Staff")
    if ! dn
      dn = DiscountName.new
      dn.description = "Staff"
      dn.available = true
      dn.save!
    end
    Default["discount_name_id_for_staff_discount"] = dn.id
  end

  def self.down
  end
end
