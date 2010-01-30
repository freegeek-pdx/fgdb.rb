class Apprentices < ActiveRecord::Migration
  def self.up
    if Default["is-pdx"] == "true"
      wt = WorkerType.find_by_name("intern")
      if wt
        wt.name = "apprentice"
        wt.save!
      end
    end
  end

  def self.down
    if Default["is-pdx"] == "true"
      wt = WorkerType.find_by_name("apprentice")
      if wt
        wt.name = "intern"
        wt.save!
      end
    end
  end
end
