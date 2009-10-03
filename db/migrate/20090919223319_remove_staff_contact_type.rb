class RemoveStaffContactType < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      ContactType.find_by_name('staff').contacts.each{|x|
        x.contact_types.delete_if{|x| x.name == "staff"}
        x.save
      }
      ContactType.find_by_name('staff').destroy
    end
  end

  def self.down
  end
end
