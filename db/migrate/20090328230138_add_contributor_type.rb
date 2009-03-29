class AddContributorType < ActiveRecord::Migration
  def self.up
    if Default["is-pdx"] == "true"
      t = ContactType.new(:for_who => 'per', :instantiable => true, :name => 'contributor', :description => 'contributor')
      t.save!
    end
  end

  def self.down
    t = ContactType.find_by_name('contributor')
    t.destroy if t
  end
end
