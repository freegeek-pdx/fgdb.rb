class AddSkedjulnatorStuff < ActiveRecord::Migration
  def self.up
  create_table "coverage_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "customizations", :force => true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "frequency_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "holidays", :force => true do |t|
    t.string  "name"
    t.date    "holiday_date"
    t.boolean "is_all_day"
    t.time    "start_time"
    t.time    "end_time"
    t.integer "frequency_type_id"
    t.integer "schedule_id"
    t.integer "weekday_id"
  end

  add_index "holidays", ["frequency_type_id"], :name => "index_holidays_on_frequency_type_id"
  add_index "holidays", ["schedule_id"], :name => "index_holidays_on_schedule_id"
  add_index "holidays", ["weekday_id"], :name => "index_holidays_on_weekday_id"

  create_table "jobs", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "coverage_type_id"
  end

  add_index "jobs", ["coverage_type_id"], :name => "index_jobs_on_coverage_type_id"

  create_table "jobs_workers", :id => false, :force => true do |t|
    t.integer "job_id"
    t.integer "worker_id"
  end

  add_index "jobs_workers", ["job_id"], :name => "index_jobs_workers_on_job_id"
  add_index "jobs_workers", ["worker_id"], :name => "index_jobs_workers_on_worker_id"
  add_index "jobs_workers", ["job_id", "worker_id"], :name => "jobs_workers_link", :unique => true

  create_table "meetings", :force => true do |t|
    t.string  "name"
    t.date    "meeting_date"
    t.time    "start_time"
    t.time    "end_time"
    t.boolean "splitable"
    t.boolean "mergeable"
    t.boolean "resizable"
    t.integer "coverage_type_id"
    t.integer "frequency_type_id"
    t.integer "schedule_id"
    t.integer "weekday_id"
    t.date    "effective_date"
    t.date    "ineffective_date"
  end

  create_table "meetings_workers", :id => false, :force => true do |t|
    t.integer "meeting_id"
    t.integer "worker_id"
  end

  add_index "meetings_workers", ["meeting_id", "worker_id"], :name => "meetings_workers_link", :unique => true

  create_table "plugin_schema_info", :id => false, :force => true do |t|
    t.string  "plugin_name"
    t.integer "version"
  end

  create_table "rr_items", :force => true do |t|
    t.integer "rr_set_id"
    t.integer "repeats_every",       :default => 1
    t.integer "repeats_on",          :default => 0
    t.boolean "weekday_0",           :default => true
    t.boolean "weekday_1",           :default => true
    t.boolean "weekday_2",           :default => true
    t.boolean "weekday_3",           :default => true
    t.boolean "weekday_4",           :default => true
    t.boolean "weekday_5",           :default => true
    t.boolean "weekday_6",           :default => true
    t.boolean "day_of_month_final",  :default => false
    t.integer "min_day_of_month"
    t.integer "max_day_of_month"
    t.boolean "week_of_month_final", :default => false
    t.boolean "week_of_month_1",     :default => true
    t.boolean "week_of_month_2",     :default => true
    t.boolean "week_of_month_3",     :default => true
    t.boolean "week_of_month_4",     :default => true
    t.boolean "week_of_month_5",     :default => true
    t.boolean "month_of_year_01",    :default => true
    t.boolean "month_of_year_02",    :default => true
    t.boolean "month_of_year_03",    :default => true
    t.boolean "month_of_year_04",    :default => true
    t.boolean "month_of_year_05",    :default => true
    t.boolean "month_of_year_06",    :default => true
    t.boolean "month_of_year_07",    :default => true
    t.boolean "month_of_year_08",    :default => true
    t.boolean "month_of_year_09",    :default => true
    t.boolean "month_of_year_11",    :default => true
    t.boolean "month_of_year_10",    :default => true
    t.boolean "month_of_year_12",    :default => true
  end

  create_table "rr_sets", :force => true do |t|
    t.string  "name"
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.integer "match_mode",       :default => 0
  end

  create_table "schedules", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.integer "parent_id"
    t.integer "repeats_every",    :default => 1
    t.integer "repeats_on",       :default => 0
    t.integer "lft"
    t.integer "rgt"
  end

  add_index "schedules", ["lft"], :name => "index_schedules_on_lft"
  add_index "schedules", ["rgt"], :name => "index_schedules_on_rgt"

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "shifts", :force => true do |t|
    t.string  "type"
    t.time    "start_time"
    t.time    "end_time"
    t.boolean "splitable"
    t.boolean "mergeable"
    t.boolean "resizable"
    t.string  "meeting_name"
    t.date    "shift_date"
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.boolean "all_day"
    t.integer "repeats_every",     :default => 1
    t.integer "repeats_on",        :default => 0
    t.integer "coverage_type_id"
    t.integer "frequency_type_id"
    t.integer "job_id"
    t.integer "meeting_id"
    t.integer "schedule_id"
    t.integer "weekday_id"
    t.integer "worker_id",         :default => 0
    t.boolean "actual",            :default => false
  end

  create_table "standard_shifts", :force => true do |t|
    t.time    "start_time"
    t.time    "end_time"
    t.boolean "splitable"
    t.boolean "mergeable"
    t.boolean "resizable"
    t.integer "coverage_type_id"
    t.integer "job_id"
    t.integer "meeting_id"
    t.integer "schedule_id"
    t.integer "weekday_id"
    t.integer "worker_id",        :default => 0
    t.date    "shift_date"
  end

  create_table "unavailabilities", :force => true do |t|
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.boolean "all_day"
    t.time    "start_time"
    t.time    "end_time"
    t.integer "repeats_every",    :default => 1
    t.integer "repeats_on",       :default => 0
    t.integer "weekday_id"
    t.integer "worker_id"
  end

  create_table "vacations", :force => true do |t|
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.boolean "is_all_day"
    t.time    "start_time"
    t.time    "end_time"
    t.integer "worker_id"
  end

  add_index "vacations", ["worker_id"], :name => "index_vacations_on_worker_id"

  create_table "weekdays", :force => true do |t|
    t.string  "name"
    t.string  "short_name"
    t.boolean "is_open"
    t.time    "start_time"
    t.time    "end_time"
  end

  create_table "work_shifts", :force => true do |t|
    t.string  "kind"
    t.time    "start_time"
    t.time    "end_time"
    t.boolean "splitable"
    t.boolean "mergeable"
    t.boolean "resizable"
    t.string  "meeting_name"
    t.date    "shift_date"
    t.date    "effective_date"
    t.date    "ineffective_date"
    t.boolean "all_day"
    t.integer "repeats_every",     :default => 1
    t.integer "repeats_on",        :default => 0
    t.integer "coverage_type_id"
    t.integer "frequency_type_id"
    t.integer "job_id"
    t.integer "meeting_id"
    t.integer "schedule_id"
    t.integer "shift_id"
    t.integer "weekday_id"
    t.integer "worker_id",         :default => 0
    t.boolean "actual",            :default => true
  end

  create_table "worker_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "workers", :force => true do |t|
    t.string  "name"
    t.float   "weekly_work_hours"
    t.float   "weekly_admin_hours"
    t.integer "worker_type_id"
    t.integer "contact_id"
    t.date    "effective_date",     :default => '1901-12-22'
    t.date    "ineffective_date",   :default => '2100-12-31'
  end

  add_index "workers", ["contact_id"], :name => "index_workers_on_contact_id"
  add_index "workers", ["worker_type_id"], :name => "index_workers_on_worker_type_id"

  add_foreign_key "holidays", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "holidays_frequency_types"
  add_foreign_key "holidays", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "holidays_schedules"
  add_foreign_key "holidays", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "holidays_weekdays"

  add_foreign_key "jobs", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "jobs_coverage_types"

  add_foreign_key "jobs_workers", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "jobs_workers_jobs"
  add_foreign_key "jobs_workers", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "jobs_workers_workers"

  add_foreign_key "meetings", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "meetings_coverage_types"
  add_foreign_key "meetings", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "meetings_frequency_types"
  add_foreign_key "meetings", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "meetings_schedules"
  add_foreign_key "meetings", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "meetings_weekdays"

  add_foreign_key "meetings_workers", ["meeting_id"], "shifts", ["id"], :on_delete => :cascade, :name => "meetings_workers_meetings"
  add_foreign_key "meetings_workers", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "meetings_workers_workers"

  add_foreign_key "rr_items", ["rr_set_id"], "rr_sets", ["id"], :on_delete => :cascade, :name => "rr_items_rr_sets"

  add_foreign_key "schedules", ["parent_id"], "schedules", ["id"], :on_delete => :cascade, :name => "schedules_schedules"

  add_foreign_key "shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "shifts_coverage_types"
  add_foreign_key "shifts", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "shifts_frequency_types"
  add_foreign_key "shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "shifts_jobs"
  add_foreign_key "shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "shifts_schedules"
  add_foreign_key "shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "shifts_weekdays"
  add_foreign_key "shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "shifts_workers"

  add_foreign_key "standard_shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "standard_shifts_coverage_types"
  add_foreign_key "standard_shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "standard_shifts_jobs"
  add_foreign_key "standard_shifts", ["meeting_id"], "meetings", ["id"], :on_delete => :cascade, :name => "standard_shifts_meetings"
  add_foreign_key "standard_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "standard_shifts_schedules"
  add_foreign_key "standard_shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "standard_shifts_weekdays"
  add_foreign_key "standard_shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "standard_shifts_workers"

  add_foreign_key "unavailabilities", ["weekday_id"], "weekdays", ["id"], :on_delete => :cascade, :name => "unavailabilities_weekdays"
  add_foreign_key "unavailabilities", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "unavailabilities_workers"

  add_foreign_key "vacations", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "vacations_workers"

  add_foreign_key "work_shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "work_shifts_coverage_types"
  add_foreign_key "work_shifts", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "work_shifts_frequency_types"
  add_foreign_key "work_shifts", ["job_id"], "jobs", ["id"], :on_delete => :set_null, :name => "work_shifts_jobs"
  add_foreign_key "work_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "work_shifts_schedules"
  add_foreign_key "work_shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "work_shifts_weekdays"
  add_foreign_key "work_shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "work_shifts_workers"

  add_foreign_key "workers", ["worker_type_id"], "worker_types", ["id"], :on_delete => :set_null, :name => "workers_worker_types"
  end

  def self.down
  end
end
