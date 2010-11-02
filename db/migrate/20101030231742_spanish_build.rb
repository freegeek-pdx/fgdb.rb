class SpanishBuild < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      p = Program.new
      p.name = "spanish"
      p.description = "Spanish Build"
      p.volunteer = true
      p.save!

      ["Spanish Build", "Spanish Build Admin", "Spanish Prebuild"].each{|x|
        q = Job.find_by_name(x)
        if q
          q.program_id = p.id
          q.save!
        end
      }
    end
  end

  def self.down
  end
end
