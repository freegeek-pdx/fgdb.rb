class CreateWorkersWorkerTypes < ActiveRecord::Migration
  def self.up
    create_table :workers_worker_types do |t|
      t.integer :worker_id, :null => false
      t.integer :worker_type_id, :null => false
      t.date :effective_on
      t.date :ineffective_on
      t.timestamps
    end
    Worker.find(:all).each{|x|
      WorkersWorkerTypes.new({:worker_id => x.id, :worker_type_id => x.worker_type.id}).save!
    }
     remove_column :workers, :worker_type_id
  end

  def self.down
    drop_table :workers_worker_types
  end
end
