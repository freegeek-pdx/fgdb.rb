class MissingForeignKeysEverywhere < ActiveRecord::Migration
  def self.up
    add_foreign_key "gizmo_returns", "contact_id", "contacts", "id", :on_delete => :restrict
    add_foreign_key "jobs", "income_stream_id", "income_streams", "id", :on_delete => :restrict
    add_foreign_key "jobs", "wc_category_id", "wc_categories", "id", :on_delete => :restrict
    add_foreign_key "jobs", "program_id", "programs", "id", :on_delete => :restrict
    add_foreign_key "points_trades", "from_contact_id", "contacts", "id", :on_delete => :restrict
    add_foreign_key "points_trades", "to_contact_id", "contacts", "id", :on_delete => :restrict
    add_foreign_key "till_adjustments", "till_type_id", "till_types", "id", :on_delete => :restrict
    add_foreign_key "worked_shifts", "worker_id", "workers", "id", :on_delete => :restrict
    add_foreign_key "worked_shifts", "job_id", "jobs", "id", :on_delete => :restrict
    add_foreign_key "workers", "contact_id", "contacts", "id", :on_delete => :restrict
    add_foreign_key "workers_worker_types", "worker_id", "workers", "id", :on_delete => :cascade
    add_foreign_key "workers_worker_types", "worker_type_id", "worker_types", "id", :on_delete => :restrict
  end

  def self.down
    remove_foreign_key "gizmo_returns", "gizmo_returns_contact_id_fk"
    remove_foreign_key "jobs", "jobs_income_stream_id_fk"
    remove_foreign_key "jobs", "jobs_wc_category_id_fk"
    remove_foreign_key "jobs", "jobs_program_id_fk"
    remove_foreign_key "points_trades", "points_trades_from_contact_id_fk"
    remove_foreign_key "points_trades", "points_trades_to_contact_id_fk"
    remove_foreign_key "till_adjustments", "till_adjustments_till_type_id_fk"
    remove_foreign_key "worked_shifts", "worked_shifts_worker_id_fk"
    remove_foreign_key "worked_shifts", "worked_shifts_job_id_fk"
    remove_foreign_key "workers", "workers_contact_id_fk"
    remove_foreign_key "workers_worker_types", "workers_worker_types_worker_id_fk"
    remove_foreign_key "workers_worker_types", "workers_worker_types_worker_type_id_fk"
  end
end
