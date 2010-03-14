class ProgramsForVolunteerTasks < ActiveRecord::Migration
  def self.up
    # add a "interns" and "other" to programs
    p = Program.new
    p.name = "intern"
    p.description = "Interns"
    p.save!
    p = Program.new
    p.name = "other"
    p.description = "Other"
    p.save!
    # add boolean field to programs called "volunteer"
    add_column :programs, :volunteer, :boolean, :default => false, :null => false
    # go through and false them all, true for interns, other, build, and adoption
    a = Program.find_all_by_name(["adoption", "build", "intern", "other"])
    a.each{|x|
      x.volunteer = true
      x.save!
    }
    # add program_id field to volunteer_task_types
    add_column :volunteer_task_types, :program_id, :integer
    # go through each volunteer_task_type. if parent.name = build, set program_id to build. adoption => adoption. program => other.
    VolunteerTaskType.find(:all).each{|x|
      parent_name = ""
      if x.parent
        parent_name = x.parent.name
      end
      program_name = ""
      if ["adoption", "build"].include?(parent_name)
        program_name = parent_name
      elsif parent_name == "program"
        program_name = "other"
      else
        program_name = ""
      end
      if !program_name.empty?
        x.program = Program.find_by_name(program_name)
        x.save!
      end
    }
    # get rid of volunteer_task_type.parent_id
    remove_column :volunteer_task_types, :parent_id
    # get rid of the adoption, build, program, and [root] volunteer_task_types.
    to_d = VolunteerTaskType.find_all_by_name(["build", "adoption", "program", "root"])
    to_d.each{|x|
      x.destroy
    }
    # add program_id to volunteer_tasks
    add_column :volunteer_tasks, :program_id, :integer
    # go through all volunteer_tasks, set program_id to volunteer_task_type.program_id. if there is none, make it 'other'.
    DB.execute("UPDATE volunteer_tasks SET program_id = (SELECT program_id FROM volunteer_task_types WHERE id = volunteer_task_type_id);")
    DB.execute("UPDATE volunteer_tasks SET program_id = (SELECT id FROM programs WHERE name = 'other') WHERE program_id IS NULL;")
    # add foreign keys and not nulls on volunteer_task_type.program_id and volunteer_task.program_id
    add_foreign_key "volunteer_task_types", ["program_id"], "programs", ["id"], :on_delete => :restrict
    add_foreign_key "volunteer_tasks", ["program_id"], "programs", ["id"], :on_delete => :restrict
    change_column :volunteer_task_types, :program_id, :integer, :null => false
    change_column :volunteer_tasks, :program_id, :integer, :null => false
  end

  def self.down
    # hah. ya, right.
  end
end
