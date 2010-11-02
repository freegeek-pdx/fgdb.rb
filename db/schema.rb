# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100626215744) do

  create_proc(:contact_trigger, [], :return => :trigger, :lang => 'plpgsql') {
    <<-contact_trigger_sql



BEGIN
    NEW.sort_name := get_sort_name(NEW.is_organization, NEW.first_name, NEW.middle_name, NEW.surname, 
NEW.organization);
    RETURN NEW;
END;



    contact_trigger_sql
  }
  create_proc(:get_sort_name, [:bool, :varchar, :varchar, :varchar, :varchar], :return => :varchar, :lang => 'plpgsql') {
    <<-get_sort_name_sql


DECLARE
    IS_ORG ALIAS FOR $1 ;
    FIRST_NAME ALIAS FOR $2 ;
    MIDDLE_NAME ALIAS FOR $3 ;
    LAST_NAME ALIAS FOR $4 ;
    ORG_NAME ALIAS FOR $5 ;

BEGIN
    IF IS_ORG = 'f' THEN
       RETURN
         SUBSTR( TRIM( LOWER(
           COALESCE(TRIM(LAST_NAME), '') ||
           COALESCE(' ' || TRIM(FIRST_NAME), '') ||
           COALESCE(' ' || TRIM(MIDDLE_NAME), '')
         )), 0, 25 );
    ELSE
       IF TRIM(ORG_NAME) ILIKE 'THE %' THEN
           -- maybe take into account A and AN as first words
           -- like this as well
           RETURN LOWER(SUBSTR(TRIM(ORG_NAME), 5, 25));
       ELSE
           RETURN SUBSTR(LOWER(TRIM(ORG_NAME)), 0, 25 );
       END IF;
    END IF;
    RETURN '';
END;



    get_sort_name_sql
  }
  create_proc(:uncertify_address, [], :return => :trigger, :lang => 'plpgsql') {
    <<-uncertify_address_sql

BEGIN
  IF tg_op = 'UPDATE' THEN
    IF ((NEW.address IS NULL != OLD.address IS NULL
         OR NEW.address != OLD.address)
         OR (NEW.extra_address IS NULL != OLD.extra_address IS NULL
             OR NEW.extra_address != OLD.extra_address)
         OR (NEW.city IS NULL != OLD.city IS NULL
             OR NEW.city != OLD.city)
         OR (NEW.state_or_province IS NULL != OLD.state_or_province IS NULL
             OR NEW.state_or_province != OLD.state_or_province)
         OR (NEW.postal_code IS NULL != OLD.postal_code IS NULL
             OR NEW.postal_code != OLD.postal_code)) THEN
      NEW.addr_certified = 'f';
    END IF;
  END IF;
  RETURN NEW;
END
    uncertify_address_sql
  }
  create_table "actions", :force => true do |t|
    t.string   "description"
    t.integer  "lock_version",               :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "created_by",                 :default => 1, :null => false
    t.integer  "updated_by",                 :default => 1, :null => false
    t.string   "name",         :limit => 40,                :null => false
  end

  add_index "actions", ["name"], :name => "actions_name_uk", :unique => true
  add_index "actions", ["description"], :name => "roles_name_index"

  create_table "community_service_types", :force => true do |t|
    t.string   "description",      :limit => 100
    t.float    "hours_multiplier",                :default => 1.0, :null => false
    t.integer  "lock_version",                    :default => 0,   :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",             :limit => 40,                   :null => false
  end

  add_index "community_service_types", ["name"], :name => "community_service_types_name_uk", :unique => true

  create_table "contact_duplicates", :force => true do |t|
    t.integer "contact_id", :null => false
    t.text    "dup_check",  :null => false
  end

  add_index "contact_duplicates", ["contact_id"], :name => "index_contact_duplicates_on_contact_id"
  add_index "contact_duplicates", ["dup_check"], :name => "index_contact_duplicates_on_dup_check"

  create_table "contact_method_types", :force => true do |t|
    t.string   "description",  :limit => 100
    t.integer  "parent_id"
    t.integer  "lock_version",                :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",         :limit => 40,                 :null => false
  end

  add_index "contact_method_types", ["name"], :name => "contact_method_types_name_uk", :unique => true

  create_table "contact_methods", :force => true do |t|
    t.integer  "contact_method_type_id",                               :null => false
    t.string   "value",                  :limit => 100,                :null => false
    t.boolean  "ok"
    t.integer  "contact_id"
    t.integer  "lock_version",                          :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "contact_methods", ["contact_id"], :name => "contact_methods_contact_id_index"

  create_table "contact_types", :force => true do |t|
    t.string   "description",  :limit => 100
    t.string   "for_who",      :limit => 3,   :default => "any"
    t.integer  "lock_version",                :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "instantiable",                :default => true,  :null => false
    t.string   "name",         :limit => 40,                     :null => false
  end

  add_index "contact_types", ["name"], :name => "contact_types_name_uk", :unique => true

  create_table "contact_types_contacts", :id => false, :force => true do |t|
    t.integer "contact_id",      :default => 0, :null => false
    t.integer "contact_type_id", :default => 0, :null => false
  end

  add_index "contact_types_contacts", ["contact_id", "contact_type_id"], :name => "contact_types_contacts_contact_id_key", :unique => true

  create_table "contacts", :force => true do |t|
    t.boolean  "is_organization",                   :default => false
    t.string   "sort_name",          :limit => 100
    t.string   "first_name",         :limit => 25
    t.string   "middle_name",        :limit => 25
    t.string   "surname",            :limit => 50
    t.string   "organization",       :limit => 100
    t.string   "extra_address",      :limit => 52
    t.string   "address",            :limit => 52
    t.string   "city",               :limit => 30
    t.string   "state_or_province",  :limit => 15
    t.string   "postal_code",        :limit => 25
    t.string   "country",            :limit => 100
    t.text     "notes"
    t.integer  "lock_version",                      :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "created_by",                                           :null => false
    t.integer  "updated_by"
    t.integer  "next_milestone",                    :default => 100
    t.boolean  "addr_certified",                    :default => false, :null => false
    t.integer  "contract_id",                       :default => 1,     :null => false
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.boolean  "fully_covered"
  end

  add_index "contacts", ["created_at"], :name => "index_contacts_on_created_at"
  add_index "contacts", ["sort_name"], :name => "index_contacts_on_sort_name"

  add_trigger(:contacts, [:insert, :update], :before => true, :row => true, :name => :contact_addr_insert_trigger, :function => :contact_trigger)
  add_trigger(:contacts, [:update], :before => true, :row => true, :name => :uncertify_address, :function => :uncertify_address)

  create_table "contacts_mailings", :force => true do |t|
    t.integer  "contact_id"
    t.integer  "mailing_id",                               :null => false
    t.boolean  "bounced",               :default => false, :null => false
    t.datetime "response_date"
    t.integer  "response_amount_cents"
    t.text     "response_note"
  end

  add_index "contacts_mailings", ["contact_id", "mailing_id"], :name => "contacts_mailings_ak", :unique => true
  add_index "contacts_mailings", ["contact_id"], :name => "index_contacts_mailings_on_contact_id"

  create_table "contracts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "label"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "instantiable", :default => true, :null => false
  end

  create_table "coverage_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "customizations", :force => true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "defaults", :force => true do |t|
    t.string   "name",         :limit => 100
    t.string   "value",        :limit => 100
    t.integer  "lock_version",                :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "disbursement_types", :force => true do |t|
    t.string   "description",  :limit => 100
    t.integer  "lock_version",                :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",         :limit => 40,                 :null => false
  end

  add_index "disbursement_types", ["name"], :name => "disbursement_types_name_uk", :unique => true

  create_table "disbursements", :force => true do |t|
    t.text     "comments"
    t.integer  "contact_id",                              :null => false
    t.integer  "disbursement_type_id",                    :null => false
    t.integer  "lock_version",         :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "disbursed_at",                            :null => false
    t.boolean  "needs_attention",      :default => false, :null => false
    t.integer  "created_by",                              :null => false
    t.integer  "updated_by"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.boolean  "adjustment",           :default => false, :null => false
  end

  add_index "disbursements", ["created_at"], :name => "disbursements_created_at_index"
  add_index "disbursements", ["contact_id"], :name => "index_disbursements_on_contact_id"

  create_table "discount_schedules", :force => true do |t|
    t.string   "description",  :limit => 25
    t.integer  "lock_version",               :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",         :limit => 40,                :null => false
  end

  add_index "discount_schedules", ["name"], :name => "discount_schedules_name_uk", :unique => true

  create_table "discount_schedules_gizmo_types", :force => true do |t|
    t.integer  "gizmo_type_id",                                                      :null => false
    t.integer  "discount_schedule_id",                                               :null => false
    t.decimal  "multiplier",           :precision => 10, :scale => 3
    t.integer  "lock_version",                                        :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "donations", :force => true do |t|
    t.integer  "contact_id"
    t.string   "postal_code",                  :limit => 25
    t.text     "comments"
    t.integer  "lock_version",                               :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "created_by",                                                    :null => false
    t.integer  "updated_by"
    t.integer  "reported_required_fee_cents"
    t.integer  "reported_suggested_fee_cents"
    t.boolean  "needs_attention",                            :default => false, :null => false
    t.datetime "invoice_resolved_at"
    t.integer  "contract_id",                                :default => 1,     :null => false
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.boolean  "adjustment",                                 :default => false, :null => false
    t.datetime "occurred_at",                                                   :null => false
  end

  add_index "donations", ["contract_id"], :name => "donations_contract_id"
  add_index "donations", ["created_at"], :name => "donations_created_at_index"
  add_index "donations", ["contact_id"], :name => "index_donations_on_contact_id"

  create_table "engine_schema_info", :id => false, :force => true do |t|
    t.string  "engine_name"
    t.integer "version"
  end

  create_table "frequency_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "generics", :force => true do |t|
    t.string   "value",       :limit => 100,                   :null => false
    t.boolean  "only_serial",                :default => true, :null => false
    t.boolean  "usable",                     :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "generics", ["value"], :name => "index_generics_on_value", :unique => true

  create_table "gizmo_categories", :force => true do |t|
    t.string "description"
    t.string "name",        :limit => 40, :null => false
  end

  add_index "gizmo_categories", ["name"], :name => "gizmo_categories_name_uk", :unique => true

  create_table "gizmo_contexts", :force => true do |t|
    t.string   "description",  :limit => 100
    t.integer  "lock_version",                :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",         :limit => 40,                 :null => false
  end

  add_index "gizmo_contexts", ["name"], :name => "gizmo_contexts_name_uk", :unique => true

  create_table "gizmo_contexts_gizmo_types", :id => false, :force => true do |t|
    t.integer  "gizmo_context_id",                :null => false
    t.integer  "gizmo_type_id",                   :null => false
    t.integer  "lock_version",     :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "gizmo_events", :force => true do |t|
    t.integer  "donation_id"
    t.integer  "sale_id"
    t.integer  "disbursement_id"
    t.integer  "recycling_id"
    t.integer  "gizmo_type_id",                        :null => false
    t.integer  "gizmo_context_id",                     :null => false
    t.integer  "gizmo_count",                          :null => false
    t.integer  "lock_version",          :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "occurred_at"
    t.integer  "unit_price_cents"
    t.boolean  "as_is"
    t.text     "description"
    t.integer  "size"
    t.integer  "recycling_contract_id"
    t.integer  "system_id"
    t.boolean  "covered"
    t.integer  "gizmo_return_id"
    t.string   "reason"
    t.string   "tester"
    t.integer  "return_sale_id"
  end

  add_index "gizmo_events", ["created_at"], :name => "gizmo_events_created_at_index"
  add_index "gizmo_events", ["disbursement_id"], :name => "gizmo_events_disbursement_id_index"
  add_index "gizmo_events", ["donation_id"], :name => "gizmo_events_donation_id_index"
  add_index "gizmo_events", ["recycling_contract_id"], :name => "gizmo_events_recycling_contract_id"
  add_index "gizmo_events", ["recycling_id"], :name => "gizmo_events_recycling_id_index"
  add_index "gizmo_events", ["sale_id"], :name => "gizmo_events_sale_id_index"
  add_index "gizmo_events", ["system_id"], :name => "gizmo_events_system_id"

  create_table "gizmo_returns", :force => true do |t|
    t.integer  "contact_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "storecredit_difference_cents"
    t.text     "comments"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "adjustment",                   :default => false, :null => false
    t.datetime "occurred_at",                                     :null => false
  end

  create_table "gizmo_types", :force => true do |t|
    t.string   "description",         :limit => 100
    t.integer  "lock_version",                       :default => 0,                     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "required_fee_cents",                                                    :null => false
    t.integer  "suggested_fee_cents",                                                   :null => false
    t.integer  "gizmo_category_id",                                                     :null => false
    t.string   "name",                :limit => 40,                                     :null => false
    t.boolean  "covered"
    t.integer  "rank"
    t.datetime "effective_on",                       :default => '2009-10-02 22:40:21'
    t.datetime "ineffective_on"
    t.string   "parent_name"
    t.boolean  "needs_id",                           :default => false,                 :null => false
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

  create_table "income_streams", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "coverage_type_id",                    :null => false
    t.integer "income_stream_id"
    t.integer "wc_category_id"
    t.integer "program_id"
    t.boolean "virtual",          :default => false, :null => false
  end

  add_index "jobs", ["coverage_type_id"], :name => "index_jobs_on_coverage_type_id"

  create_table "jobs_workers", :id => false, :force => true do |t|
    t.integer "job_id"
    t.integer "worker_id"
  end

  add_index "jobs_workers", ["job_id"], :name => "index_jobs_workers_on_job_id"
  add_index "jobs_workers", ["worker_id"], :name => "index_jobs_workers_on_worker_id"
  add_index "jobs_workers", ["job_id", "worker_id"], :name => "jobs_workers_link", :unique => true

  create_table "logs", :force => true do |t|
    t.string   "table_name"
    t.string   "action"
    t.integer  "user_id"
    t.integer  "thing_id"
    t.datetime "date"
    t.integer  "cashier_id"
  end

  create_table "mailings", :force => true do |t|
    t.string   "name",        :limit => 20
    t.string   "description", :limit => 100, :null => false
    t.integer  "created_by",                 :null => false
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "notes", :force => true do |t|
    t.integer  "contact_id"
    t.integer  "system_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pay_periods", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_methods", :force => true do |t|
    t.string   "description",  :limit => 100
    t.integer  "lock_version",                :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",         :limit => 40,                 :null => false
  end

  add_index "payment_methods", ["name"], :name => "payment_methods_name_uk", :unique => true

  create_table "payments", :force => true do |t|
    t.integer  "donation_id"
    t.integer  "sale_id"
    t.integer  "payment_method_id",                :null => false
    t.integer  "lock_version",      :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "amount_cents"
  end

  add_index "payments", ["donation_id"], :name => "payments_donation_id_index"
  add_index "payments", ["sale_id"], :name => "payments_sale_id_index"

  create_table "plugin_schema_info", :id => false, :force => true do |t|
    t.string  "plugin_name"
    t.integer "version"
  end

  create_table "points_trades", :force => true do |t|
    t.integer  "from_contact_id"
    t.integer  "to_contact_id"
    t.decimal  "points"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programs", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "volunteer",   :default => false, :null => false
  end

  create_table "recyclings", :force => true do |t|
    t.text     "comments"
    t.integer  "lock_version",       :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "recycled_at",                           :null => false
    t.boolean  "needs_attention",    :default => false, :null => false
    t.integer  "created_by",                            :null => false
    t.integer  "updated_by"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.boolean  "adjustment",         :default => false, :null => false
  end

  add_index "recyclings", ["created_at"], :name => "recyclings_created_at_index"

  create_table "roles", :force => true do |t|
    t.string   "name",       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "roles_users_uk", :unique => true

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

  create_table "sales", :force => true do |t|
    t.integer  "contact_id"
    t.string   "postal_code",                    :limit => 25
    t.integer  "discount_schedule_id",                                            :null => false
    t.text     "comments"
    t.boolean  "bulk"
    t.integer  "lock_version",                                 :default => 0,     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "created_by",                                                      :null => false
    t.integer  "updated_by"
    t.integer  "reported_discount_amount_cents"
    t.integer  "reported_amount_due_cents"
    t.boolean  "needs_attention",                              :default => false, :null => false
    t.datetime "invoice_resolved_at"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.boolean  "adjustment",                                   :default => false, :null => false
    t.datetime "occurred_at",                                                     :null => false
  end

  add_index "sales", ["contact_id"], :name => "sales_contact_id"
  add_index "sales", ["created_at"], :name => "sales_created_at_index"

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

  create_table "spec_sheets", :force => true do |t|
    t.integer  "system_id"
    t.integer  "contact_id",                     :null => false
    t.integer  "action_id",                      :null => false
    t.integer  "lock_version",    :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "old_id"
    t.text     "notes"
    t.integer  "type_id",                        :null => false
    t.string   "os"
    t.boolean  "flag"
    t.text     "cleaned_output"
    t.text     "original_output"
    t.boolean  "cleaned_valid"
    t.boolean  "original_valid"
  end

  add_index "spec_sheets", ["contact_id"], :name => "reports_contact_id_index"
  add_index "spec_sheets", ["action_id"], :name => "reports_role_id_index"
  add_index "spec_sheets", ["system_id"], :name => "reports_system_id_index"
  add_index "spec_sheets", ["type_id"], :name => "reports_type_id_index"

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

  create_table "store_credits", :force => true do |t|
    t.integer  "gizmo_return_id"
    t.integer  "gizmo_event_id"
    t.integer  "payment_id"
    t.integer  "amount_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "expire_date"
  end

  create_table "systems", :force => true do |t|
    t.string   "system_vendor"
    t.string   "system_model"
    t.string   "system_serial_number"
    t.integer  "lock_version",         :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "mobo_vendor"
    t.string   "mobo_model"
    t.string   "mobo_serial_number"
    t.string   "serial_number"
    t.string   "vendor"
    t.string   "model"
    t.integer  "contract_id",          :default => 1, :null => false
    t.boolean  "covered"
  end

  add_index "systems", ["contract_id"], :name => "systems_contract_id"
  add_index "systems", ["system_model"], :name => "systems_model_index"
  add_index "systems", ["system_serial_number"], :name => "systems_serial_number_index"
  add_index "systems", ["system_vendor"], :name => "systems_vendor_index"

  create_table "till_adjustments", :force => true do |t|
    t.integer  "till_type_id"
    t.date     "till_date"
    t.integer  "adjustment_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "till_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  add_index "till_types", ["name"], :name => "index_till_types_on_name", :unique => true

  create_table "types", :force => true do |t|
    t.string   "description"
    t.integer  "lock_version",               :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "created_by",                 :default => 1, :null => false
    t.integer  "updated_by",                 :default => 1, :null => false
    t.string   "name",         :limit => 40,                :null => false
  end

  add_index "types", ["description"], :name => "types_name_index"
  add_index "types", ["name"], :name => "types_name_uk", :unique => true

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

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "contact_id"
    t.integer  "created_by",                                                :null => false
    t.integer  "updated_by"
    t.integer  "cashier_code"
    t.boolean  "can_login",                               :default => true, :null => false
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

  create_table "volunteer_task_types", :force => true do |t|
    t.string   "description",      :limit => 100
    t.decimal  "hours_multiplier",                :precision => 10, :scale => 3, :default => 1.0,                   :null => false
    t.boolean  "instantiable",                                                   :default => true,                  :null => false
    t.integer  "lock_version",                                                   :default => 0,                     :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",             :limit => 40,                                                                    :null => false
    t.datetime "effective_on",                                                   :default => '2009-10-02 22:40:21'
    t.datetime "ineffective_on"
    t.integer  "program_id",                                                                                        :null => false
  end

  create_table "volunteer_tasks", :force => true do |t|
    t.integer  "contact_id"
    t.float    "duration"
    t.integer  "lock_version",              :default => 0, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "community_service_type_id"
    t.integer  "volunteer_task_type_id"
    t.date     "date_performed"
    t.integer  "created_by",                               :null => false
    t.integer  "updated_by"
    t.integer  "cashier_created_by"
    t.integer  "cashier_updated_by"
    t.integer  "program_id",                               :null => false
  end

  add_index "volunteer_tasks", ["community_service_type_id"], :name => "index_volunteer_tasks_on_community_service_type_id"
  add_index "volunteer_tasks", ["date_performed"], :name => "index_volunteer_tasks_on_date_performed"
  add_index "volunteer_tasks", ["duration"], :name => "index_volunteer_tasks_on_duration"
  add_index "volunteer_tasks", ["volunteer_task_type_id"], :name => "index_volunteer_tasks_on_volunteer_task_type_id"
  add_index "volunteer_tasks", ["contact_id"], :name => "volunteer_tasks_contact_id_index"

  create_table "wc_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "rate_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "worked_shifts", :force => true do |t|
    t.integer  "worker_id"
    t.integer  "job_id"
    t.date     "date_performed"
    t.decimal  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "worker_types", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "workers", :force => true do |t|
    t.string  "name"
    t.float   "weekly_work_hours"
    t.float   "weekly_admin_hours"
    t.integer "contact_id"
    t.float   "sunday"
    t.float   "monday"
    t.float   "tuesday"
    t.float   "wednesday"
    t.float   "thursday"
    t.float   "friday"
    t.float   "saturday"
    t.boolean "salaried"
    t.float   "pto_rate"
    t.float   "floor_hours"
    t.float   "ceiling_hours"
    t.boolean "virtual",            :default => false, :null => false
  end

  add_index "workers", ["contact_id"], :name => "index_workers_on_contact_id"

  create_table "workers_worker_types", :force => true do |t|
    t.integer  "worker_id",      :null => false
    t.integer  "worker_type_id", :null => false
    t.date     "effective_on"
    t.date     "ineffective_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "actions", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "actions_created_by_fkey"
  add_foreign_key "actions", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "actions_updated_by_fkey"

  add_foreign_key "contact_duplicates", ["contact_id"], "contacts", ["id"], :name => "contact_duplicates_contact_id_fkey"

  add_foreign_key "contact_method_types", ["parent_id"], "contact_method_types", ["id"], :on_delete => :set_null, :name => "contact_method_types_parent_id_fk"

  add_foreign_key "contact_methods", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "contact_methods_contact_id_fk"
  add_foreign_key "contact_methods", ["contact_method_type_id"], "contact_method_types", ["id"], :on_delete => :restrict, :name => "contact_methods_contact_method_type_fk"

  add_foreign_key "contact_types_contacts", ["contact_type_id"], "contact_types", ["id"], :on_delete => :restrict, :name => "contact_types_contacts_contact_types_contacts_fk"
  add_foreign_key "contact_types_contacts", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "contact_types_contacts_contacts_fk"

  add_foreign_key "contacts", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "contacts_contract_id_fkey"
  add_foreign_key "contacts", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_created_by_fkey"
  add_foreign_key "contacts", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_updated_by_fkey"

  add_foreign_key "contacts_mailings", ["contact_id"], "contacts", ["id"], :name => "contacts_mailings_contact_id_fkey"
  add_foreign_key "contacts_mailings", ["mailing_id"], "mailings", ["id"], :name => "contacts_mailings_mailing_id_fkey"

  add_foreign_key "disbursements", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "disbursements_contacts_fk"
  add_foreign_key "disbursements", ["disbursement_type_id"], "disbursement_types", ["id"], :on_delete => :restrict, :name => "disbursements_disbursements_type_id_fk"

  add_foreign_key "discount_schedules_gizmo_types", ["discount_schedule_id"], "discount_schedules", ["id"], :on_delete => :cascade, :name => "discount_schedules_gizmo_types_discount_schedules_fk"
  add_foreign_key "discount_schedules_gizmo_types", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :cascade, :name => "discount_schedules_gizmo_types_gizmo_types_fk"

  add_foreign_key "donations", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "donations_contacts_fk"
  add_foreign_key "donations", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "donations_contract_id_fkey"
  add_foreign_key "donations", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_created_by_fkey"
  add_foreign_key "donations", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_updated_by_fkey"

  add_foreign_key "gizmo_contexts_gizmo_types", ["gizmo_context_id"], "gizmo_contexts", ["id"], :on_delete => :cascade, :name => "gizmo_contexts_gizmo_types_gizmo_contexts_fk"
  add_foreign_key "gizmo_contexts_gizmo_types", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :cascade, :name => "gizmo_contexts_gizmo_types_gizmo_types_fk"

  add_foreign_key "gizmo_events", ["disbursement_id"], "disbursements", ["id"], :name => "gizmo_events_disbursements_fk"
  add_foreign_key "gizmo_events", ["donation_id"], "donations", ["id"], :on_delete => :set_null, :name => "gizmo_events_donations_fk"
  add_foreign_key "gizmo_events", ["gizmo_context_id"], "gizmo_contexts", ["id"], :on_delete => :restrict, :name => "gizmo_events_gizmo_contexts_fk"
  add_foreign_key "gizmo_events", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :restrict, :name => "gizmo_events_gizmo_types_fk"
  add_foreign_key "gizmo_events", ["recycling_contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "gizmo_events_recycling_contract_id_fkey"
  add_foreign_key "gizmo_events", ["recycling_id"], "recyclings", ["id"], :on_delete => :set_null, :name => "gizmo_events_recyclings_fk"
  add_foreign_key "gizmo_events", ["return_sale_id"], "sales", ["id"], :on_delete => :restrict, :name => "gizmo_events_return_sale_id_fk"
  add_foreign_key "gizmo_events", ["sale_id"], "sales", ["id"], :on_delete => :set_null, :name => "gizmo_events_sales_fk"
  add_foreign_key "gizmo_events", ["system_id"], "systems", ["id"], :on_delete => :restrict, :name => "gizmo_events_system_id_fkey"

  add_foreign_key "gizmo_returns", ["contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "gizmo_returns_contact_id_fkey"

  add_foreign_key "gizmo_types", ["gizmo_category_id"], "gizmo_categories", ["id"], :name => "gizmo_types_gizmo_categories_fk"

  add_foreign_key "holidays", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "holidays_frequency_types"
  add_foreign_key "holidays", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "holidays_schedules"
  add_foreign_key "holidays", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "holidays_weekdays"

  add_foreign_key "jobs", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "jobs_coverage_types"
  add_foreign_key "jobs", ["income_stream_id"], "income_streams", ["id"], :on_delete => :restrict, :name => "jobs_income_stream_id_fkey"
  add_foreign_key "jobs", ["program_id"], "programs", ["id"], :on_delete => :restrict, :name => "jobs_program_id_fkey"
  add_foreign_key "jobs", ["wc_category_id"], "wc_categories", ["id"], :on_delete => :restrict, :name => "jobs_wc_category_id_fkey"

  add_foreign_key "jobs_workers", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "jobs_workers_jobs"
  add_foreign_key "jobs_workers", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "jobs_workers_workers"

  add_foreign_key "mailings", ["created_by"], "contacts", ["id"], :name => "mailings_created_by_fkey"
  add_foreign_key "mailings", ["updated_by"], "contacts", ["id"], :name => "mailings_updated_by_fkey"

  add_foreign_key "meetings", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "meetings_coverage_types"
  add_foreign_key "meetings", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "meetings_frequency_types"
  add_foreign_key "meetings", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "meetings_schedules"
  add_foreign_key "meetings", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "meetings_weekdays"

  add_foreign_key "meetings_workers", ["meeting_id"], "shifts", ["id"], :on_delete => :cascade, :name => "meetings_workers_meetings"
  add_foreign_key "meetings_workers", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "meetings_workers_workers"

  add_foreign_key "notes", ["contact_id"], "contacts", ["id"], :name => "notes_contact_id_fkey"
  add_foreign_key "notes", ["system_id"], "systems", ["id"], :name => "notes_system_id_fkey"

  add_foreign_key "payments", ["donation_id"], "donations", ["id"], :on_delete => :cascade, :name => "payments_donation_id_fk"
  add_foreign_key "payments", ["payment_method_id"], "payment_methods", ["id"], :on_delete => :restrict, :name => "payments_payment_methods_fk"
  add_foreign_key "payments", ["sale_id"], "sales", ["id"], :name => "payments_sale_txn_id_fkey"

  add_foreign_key "points_trades", ["from_contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "points_trades_from_contact_id_fkey"
  add_foreign_key "points_trades", ["to_contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "points_trades_to_contact_id_fkey"

  add_foreign_key "roles_users", ["role_id"], "roles", ["id"], :on_delete => :cascade, :name => "roles_users_role_id_fkey"
  add_foreign_key "roles_users", ["user_id"], "users", ["id"], :on_delete => :cascade, :name => "roles_users_user_id_fkey"

  add_foreign_key "rr_items", ["rr_set_id"], "rr_sets", ["id"], :on_delete => :cascade, :name => "rr_items_rr_sets"

  add_foreign_key "sales", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "sales_contacts_fk"
  add_foreign_key "sales", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_created_by_fkey"
  add_foreign_key "sales", ["discount_schedule_id"], "discount_schedules", ["id"], :on_delete => :restrict, :name => "sales_discount_schedules_fk"
  add_foreign_key "sales", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_updated_by_fkey"

  add_foreign_key "schedules", ["parent_id"], "schedules", ["id"], :on_delete => :cascade, :name => "schedules_schedules"

  add_foreign_key "shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "shifts_coverage_types"
  add_foreign_key "shifts", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "shifts_frequency_types"
  add_foreign_key "shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "shifts_jobs"
  add_foreign_key "shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "shifts_schedules"
  add_foreign_key "shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "shifts_weekdays"
  add_foreign_key "shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "shifts_workers"

  add_foreign_key "spec_sheets", ["action_id"], "actions", ["id"], :name => "spec_sheets_action_id_fkey"
  add_foreign_key "spec_sheets", ["contact_id"], "contacts", ["id"], :name => "spec_sheets_contact_id_fkey"
  add_foreign_key "spec_sheets", ["system_id"], "systems", ["id"], :name => "spec_sheets_system_id_fkey"
  add_foreign_key "spec_sheets", ["type_id"], "types", ["id"], :name => "spec_sheets_type_id_fkey"

  add_foreign_key "standard_shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "standard_shifts_coverage_types"
  add_foreign_key "standard_shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "standard_shifts_jobs"
  add_foreign_key "standard_shifts", ["meeting_id"], "meetings", ["id"], :on_delete => :cascade, :name => "standard_shifts_meetings"
  add_foreign_key "standard_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "standard_shifts_schedules"
  add_foreign_key "standard_shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "standard_shifts_weekdays"
  add_foreign_key "standard_shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "standard_shifts_workers"

  add_foreign_key "store_credits", ["gizmo_event_id"], "gizmo_events", ["id"], :on_delete => :cascade, :name => "store_credits_gizmo_event_id_fkey"
  add_foreign_key "store_credits", ["gizmo_return_id"], "gizmo_returns", ["id"], :on_delete => :cascade, :name => "store_credits_gizmo_return_id_fkey"
  add_foreign_key "store_credits", ["payment_id"], "payments", ["id"], :on_delete => :set_null, :name => "store_credits_payment_id_fkey"

  add_foreign_key "systems", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "systems_contract_id_fkey"

  add_foreign_key "till_adjustments", ["till_type_id"], "till_types", ["id"], :on_delete => :restrict, :name => "till_adjustments_till_type_id_fkey"

  add_foreign_key "types", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "types_created_by_fkey"
  add_foreign_key "types", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "types_updated_by_fkey"

  add_foreign_key "unavailabilities", ["weekday_id"], "weekdays", ["id"], :on_delete => :cascade, :name => "unavailabilities_weekdays"
  add_foreign_key "unavailabilities", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "unavailabilities_workers"

  add_foreign_key "users", ["contact_id"], "contacts", ["id"], :name => "users_contacts_fk"
  add_foreign_key "users", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "users_created_by_fkey"
  add_foreign_key "users", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "users_updated_by_fkey"

  add_foreign_key "vacations", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "vacations_workers"

  add_foreign_key "volunteer_tasks", ["community_service_type_id"], "community_service_types", ["id"], :on_delete => :set_null, :name => "volunteer_tasks_community_service_type_id_fkey"
  add_foreign_key "volunteer_tasks", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "volunteer_tasks_contacts_fk"
  add_foreign_key "volunteer_tasks", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_created_by_fkey"
  add_foreign_key "volunteer_tasks", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_updated_by_fkey"
  add_foreign_key "volunteer_tasks", ["volunteer_task_type_id"], "volunteer_task_types", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_volunteer_task_type_id_fk"

  add_foreign_key "work_shifts", ["coverage_type_id"], "coverage_types", ["id"], :on_delete => :set_null, :name => "work_shifts_coverage_types"
  add_foreign_key "work_shifts", ["frequency_type_id"], "frequency_types", ["id"], :on_delete => :set_null, :name => "work_shifts_frequency_types"
  add_foreign_key "work_shifts", ["job_id"], "jobs", ["id"], :on_delete => :set_null, :name => "work_shifts_jobs"
  add_foreign_key "work_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "work_shifts_schedules"
  add_foreign_key "work_shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "work_shifts_weekdays"
  add_foreign_key "work_shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "work_shifts_workers"

  add_foreign_key "worked_shifts", ["job_id"], "jobs", ["id"], :on_delete => :restrict, :name => "worked_shifts_job_id_fkey"
  add_foreign_key "worked_shifts", ["worker_id"], "workers", ["id"], :on_delete => :restrict, :name => "worked_shifts_worker_id_fkey"

  add_foreign_key "workers", ["contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "workers_contact_id_fkey"

  add_foreign_key "workers_worker_types", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "workers_worker_types_worker_id_fkey"
  add_foreign_key "workers_worker_types", ["worker_type_id"], "worker_types", ["id"], :on_delete => :restrict, :name => "workers_worker_types_worker_type_id_fkey"

  create_view "v_donation_totals", "SELECT d.id, sum(p.amount_cents) AS total_paid FROM (donations d LEFT JOIN payments p ON ((p.donation_id = d.id))) GROUP BY d.id;", :force => true do |v|
    v.column :id
    v.column :total_paid
  end

  create_view "v_donations", "SELECT d.id, d.contact_id, d.postal_code, d.comments, d.lock_version, d.updated_at, d.created_at, d.created_by, d.updated_by, d.reported_required_fee_cents, d.reported_suggested_fee_cents, v.total_paid, CASE WHEN (v.total_paid > d.reported_required_fee_cents) THEN (d.reported_required_fee_cents)::bigint ELSE v.total_paid END AS fees_paid, CASE WHEN (v.total_paid < d.reported_required_fee_cents) THEN (0)::bigint ELSE (v.total_paid - d.reported_required_fee_cents) END AS donations_paid FROM (donations d JOIN v_donation_totals v ON ((d.id = v.id)));", :force => true do |v|
    v.column :id
    v.column :contact_id
    v.column :postal_code
    v.column :comments
    v.column :lock_version
    v.column :updated_at
    v.column :created_at
    v.column :created_by
    v.column :updated_by
    v.column :reported_required_fee_cents
    v.column :reported_suggested_fee_cents
    v.column :total_paid
    v.column :fees_paid
    v.column :donations_paid
  end

end
