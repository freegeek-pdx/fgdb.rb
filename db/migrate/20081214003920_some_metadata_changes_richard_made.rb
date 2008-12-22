class SomeMetadataChangesRichardMade < ActiveRecord::Migration
  def self.up
    # #573 (may be used in code someday)
    if !ContactType.find_by_name("nomail")
      ct = ContactType.new
      ct.name = "nomail"
      ct.description = "no mail"
      ct.save!
    end
    # #574 (everybody wants generics! :D)
    for i in ["V        H 8\\", "VH\\"]
      if !Generic.find_by_value(i)
        g = Generic.new
        g.value = i
        g.save!
      end
    end
    if Default["is-pdx"] == "true"
      # #547
      begin
        drop_table :backuptable # our weird stuff
      rescue
      end
      # #579
      if !VolunteerTaskType.find_by_name('case management') # our stuff
        vt = VolunteerTaskType.new
        vt.name = 'case management'
        vt.description = 'case management'
        vt.parent_id = 24
        vt.save!
      end
    end
  end

  def self.down
  end
end
