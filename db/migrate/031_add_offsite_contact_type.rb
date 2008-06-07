class AddOffsiteContactType < ActiveRecord::Migration
  def self.up
    if ContactType.find(:first, :conditions=>"description='offsite'").nil?()
      ContactType.new(:description=>'offsite',
                      :for_who=>'per'
                     ).save()
    end
  end

  def self.down
    x = ContactType.find(:first, :conditions=>"description='offsite'")
    unless x.nil?
      x.destroy()
    end
  end
end
