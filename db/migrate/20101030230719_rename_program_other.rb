class RenameProgramOther < ActiveRecord::Migration
  def self.up
    p = Program.find_by_name("other")
    if Default.is_pdx && p
      p.name = "mixed"
      p.description = "Mixed"
      p.save!
    end
  end

  def self.down
  end
end
