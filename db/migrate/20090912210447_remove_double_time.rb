class RemoveDoubleTime < ActiveRecord::Migration
  def self.up
    if Default.is_pdx
      now = DateTime.now
      DB.sql("DROP INDEX volunteer_task_types_name_uk;")
      DB.sql("INSERT INTO volunteer_task_types(description,parent_id,hours_multiplier,instantiable,lock_version,updated_at,created_at,name,effective_on,ineffective_on) (SELECT description,parent_id,1.000,instantiable,lock_version,updated_at,created_at,name,effective_on,ineffective_on FROM volunteer_task_types WHERE name = 'cleaning' OR name = 'monitors');")
      for i in ['cleaning', 'monitors']
        list = VolunteerTaskType.find_all_by_name(i).sort_by(&:id)
        old = list.first
        new = list.last
        old.ineffective_on = now
        new.effective_on = now
        old.save!
        new.save!
      end
    end
  end

  def self.down
    if Default.is_pdx
      for i in ['cleaning', 'monitors']
        list = VolunteerTaskType.find_all_by_name(i).sort_by(&:id)
        new = list.destroy
        old.ineffective_on = nil
        old.save!
      end
    end
  end
end
