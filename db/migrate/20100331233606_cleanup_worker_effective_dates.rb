class CleanupWorkerEffectiveDates < ActiveRecord::Migration
  # SELECT workers.id AS id, workers.name AS worker_name, worker_types.name AS worker_type_name, workers_worker_types.effective_on AS worker_type_effective, workers_worker_types.ineffective_on AS worker_type_ineffective, workers.effective_date AS worker_effective, workers.ineffective_date AS worker_ineffective FROM workers_worker_types JOIN workers ON workers.id = workers_worker_types.worker_id JOIN worker_types ON worker_types.id = workers_worker_types.worker_type_id WHERE (worker_id IN (SELECT worker_id AS count FROM workers_worker_types GROUP BY worker_id HAVING count(*) > 1) OR worker_id IN (SELECT worker_id FROM workers_worker_types WHERE effective_on IS NOT NULL OR ineffective_on IS NOT NULL)) ORDER BY worker_id, effective_on;

  def self.up
    DB.exec("UPDATE workers_worker_types SET effective_on = effective_date FROM workers WHERE workers.id = workers_worker_types.worker_id AND effective_on IS NULL AND worker_id NOT IN (6352, 26999, 37673, 60004);")
    DB.exec("UPDATE workers_worker_types SET ineffective_on = ineffective_date FROM workers WHERE workers.id = workers_worker_types.worker_id AND ineffective_on IS NULL AND worker_id NOT IN (6352, 26999, 37673, 60004);")
    DB.exec("UPDATE workers_worker_types SET effective_on = NULL WHERE effective_on = '2001-01-01'")
    DB.exec("UPDATE workers_worker_types SET ineffective_on = NULL WHERE ineffective_on IN ('2015-12-31', '2010-12-31')")
    Worker.all.each{|x|
      all = x.workers_worker_types.sort_by(&:smart_effective_on)
      first = all.first
      last = all.last
      if first.effective_on != nil
        WorkersWorkerType.new(:worker_id => x.id, :worker_type_id => 50, :ineffective_on => first.effective_on, :effective_on => nil).save!
      end
      if last.ineffective_on != nil
        WorkersWorkerType.new(:worker_id => x.id, :worker_type_id => 50, :effective_on => last.ineffective_on, :ineffective_on => nil).save!
      end
    }
    Worker.all.each{|x| x.purify_worker_types}
    remove_column(:workers, :effective_date)
    remove_column(:workers, :ineffective_date)
  end

  def self.down
  end
end
