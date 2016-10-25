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

ActiveRecord::Schema.define(:version => 20151019202450) do

  create_proc(:combine_four, [:varchar, :varchar, :varchar, :varchar], :return => :varchar, :resource => ['', 'DECLARE
        result character varying;
BEGIN
        result = \'\';
        result = result || coalesce(\' \' || $1, \'\');
        result = result || coalesce(\' \' || $2, \'\');
        result = result || coalesce(\' \' || $3, \'\');
        result = result || coalesce(\' \' || $4, \'\');
        RETURN result;
END;
'], :lang => 'plpgsql')
  create_proc(:contact_trigger, [], :return => :trigger, :resource => ['', '



BEGIN
    NEW.sort_name := get_sort_name(NEW.is_organization, NEW.first_name, NEW.middle_name, NEW.surname, 
NEW.organization);
    RETURN NEW;
END;



'], :lang => 'plpgsql')
  create_proc(:get_match_score, [:varchar, :varchar], :return => :int4, :resource => ['', 'DECLARE
        score integer ;
        inwords ALIAS FOR $1 ;
        interms ALIAS FOR $2 ;
        words character varying [];
        terms character varying [];
        iterm integer;
        iword integer;
        term character varying ;
        word character varying ;
BEGIN
        words = string_to_array(inwords, \' \');
        terms = string_to_array(interms, \' \');
        score = 0;
        FOR iterm in 1 .. array_upper(terms, 1) LOOP
              term = terms[ iterm ];
              IF term <> \'\' AND array_upper(words, 1) > 1 THEN
              FOR iword in 1 ..  array_upper(words, 1) LOOP
              word = words[ iword ];
              IF word <> \'\' AND word ILIKE \'%\' || term || \'%\' THEN
                 score = score + 1;
              END IF;
              END LOOP;
              END IF;
        END LOOP;
        RETURN score;
END;
'], :lang => 'plpgsql')
  create_proc(:get_sort_name, [:bool, :varchar, :varchar, :varchar, :varchar], :return => :varchar, :resource => ['', '


DECLARE
    IS_ORG ALIAS FOR $1 ;
    FIRST_NAME ALIAS FOR $2 ;
    MIDDLE_NAME ALIAS FOR $3 ;
    LAST_NAME ALIAS FOR $4 ;
    ORG_NAME ALIAS FOR $5 ;

BEGIN
    IF IS_ORG = \'f\' THEN
       RETURN
         SUBSTR( TRIM( LOWER(
           COALESCE(TRIM(LAST_NAME), \'\') ||
           COALESCE(\' \' || TRIM(FIRST_NAME), \'\') ||
           COALESCE(\' \' || TRIM(MIDDLE_NAME), \'\')
         )), 0, 25 );
    ELSE
       IF TRIM(ORG_NAME) ILIKE \'THE %\' THEN
           -- maybe take into account A and AN as first words
           -- like this as well
           RETURN LOWER(SUBSTR(TRIM(ORG_NAME), 5, 25));
       ELSE
           RETURN SUBSTR(LOWER(TRIM(ORG_NAME)), 0, 25 );
       END IF;
    END IF;
    RETURN \'\';
END;



'], :lang => 'plpgsql')
  create_proc(:uncertify_address, [], :return => :trigger, :resource => ['', '
BEGIN
  IF tg_op = \'UPDATE\' THEN
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
      NEW.addr_certified = \'f\';
    END IF;
  END IF;
  RETURN NEW;
END
'], :lang => 'plpgsql')
  create_proc(:db_to_csv, [:text], :return => nil, :resource => ['', '
declare
  tables RECORD;
  statement TEXT;
begin
  FOR tables IN 
    SELECT (table_schema || \'.\' || table_name) AS schema_table
    FROM information_schema.tables t INNER JOIN information_schema.schemata s 
    ON s.schema_name = t.table_schema 
    WHERE t.table_schema NOT IN (\'pg_catalog\', \'information_schema\', \'configuration\')
    AND table_name NOT IN (\'spec_sheets\', \'logs\', \'contacts\')
    AND table_type NOT LIKE \'VIEW\'
    ORDER BY schema_table
  LOOP
    statement := \'COPY \' || tables.schema_table || \' TO \'\'\' || path || \'/\' || tables.schema_table || \'.csv\' ||\'\'\' DELIMITER \'\',\'\' CSV HEADER\';
    EXECUTE statement;
  END LOOP;
  return;  
end;
'], :lang => 'plpgsql')
# Could not dump table "actions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... (T.tgrelid = C.OID AND C.relname = 'actions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'actions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "assignments" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'assignments' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'assignments' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "attendance_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'attendance_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'attendance_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "builder_tasks" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'builder_tasks' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'builder_tasks' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "call_status_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...d = C.OID AND C.relname = 'call_status_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'call_status_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "community_service_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...OID AND C.relname = 'community_service_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'community_service_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_duplicates" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... = C.OID AND C.relname = 'contact_duplicates' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_duplicates' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_method_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'contact_method_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_method_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_methods" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'contact_methods' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_methods' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'contact_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_types_contacts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....OID AND C.relname = 'contact_types_contacts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_types_contacts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contact_volunteer_task_type_counts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elname = 'contact_volunteer_task_type_counts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contact_volunteer_task_type_counts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contacts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'contacts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contacts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contacts_mailings" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...d = C.OID AND C.relname = 'contacts_mailings' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contacts_mailings' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "contracts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...T.tgrelid = C.OID AND C.relname = 'contracts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'contracts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "customizations" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elid = C.OID AND C.relname = 'customizations' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'customizations' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "default_assignments" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...= C.OID AND C.relname = 'default_assignments' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'default_assignments' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "defaults" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'defaults' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'defaults' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disbursement_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... = C.OID AND C.relname = 'disbursement_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disbursement_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disbursements" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'disbursements' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disbursements' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disciplinary_action_areas" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...D AND C.relname = 'disciplinary_action_areas' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disciplinary_action_areas' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disciplinary_action_areas_disciplinary_actions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...sciplinary_action_areas_disciplinary_actions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disciplinary_action_areas_disciplinary_actions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disciplinary_actions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'disciplinary_actions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disciplinary_actions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "discount_names" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elid = C.OID AND C.relname = 'discount_names' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'discount_names' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "discount_percentages" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'discount_percentages' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'discount_percentages' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disktest_batch_drives" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...C.OID AND C.relname = 'disktest_batch_drives' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disktest_batch_drives' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disktest_batches" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'disktest_batches' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disktest_batches' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "disktest_runs" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'disktest_runs' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'disktest_runs' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "donations" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...T.tgrelid = C.OID AND C.relname = 'donations' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'donations' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "engine_schema_info" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... = C.OID AND C.relname = 'engine_schema_info' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'engine_schema_info' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "generics" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'generics' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'generics' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_categories" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'gizmo_categories' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_categories' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_contexts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elid = C.OID AND C.relname = 'gizmo_contexts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_contexts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_contexts_gizmo_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... AND C.relname = 'gizmo_contexts_gizmo_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_contexts_gizmo_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_events" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...grelid = C.OID AND C.relname = 'gizmo_events' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_events' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_returns" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'gizmo_returns' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_returns' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_type_groups" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...d = C.OID AND C.relname = 'gizmo_type_groups' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_type_groups' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_type_groups_gizmo_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...D C.relname = 'gizmo_type_groups_gizmo_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_type_groups_gizmo_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "gizmo_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'gizmo_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'gizmo_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "holidays" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'holidays' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'holidays' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "income_streams" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elid = C.OID AND C.relname = 'income_streams' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'income_streams' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "jobs" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... ON (T.tgrelid = C.OID AND C.relname = 'jobs' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'jobs' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "logs" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... ON (T.tgrelid = C.OID AND C.relname = 'logs' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'logs' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "mailings" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'mailings' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'mailings' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "meeting_minders" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'meeting_minders' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'meeting_minders' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "meetings_workers" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'meetings_workers' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'meetings_workers' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "newsletter_subscribers" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....OID AND C.relname = 'newsletter_subscribers' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'newsletter_subscribers' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "notes" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'notes' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'notes' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "pay_periods" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'pay_periods' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'pay_periods' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "payment_methods" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'payment_methods' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'payment_methods' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "payments" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'payments' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'payments' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "plugin_schema_info" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... = C.OID AND C.relname = 'plugin_schema_info' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'plugin_schema_info' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "points_trades" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'points_trades' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'points_trades' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "postal_codes" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...grelid = C.OID AND C.relname = 'postal_codes' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'postal_codes' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "pricing_datas" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'pricing_datas' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'pricing_datas' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "pricing_types_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...= C.OID AND C.relname = 'pricing_types_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'pricing_types_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "privileges" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....tgrelid = C.OID AND C.relname = 'privileges' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'privileges' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "privileges_roles" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'privileges_roles' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'privileges_roles' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "programs" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'programs' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'programs' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "recycling_shipments" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...= C.OID AND C.relname = 'recycling_shipments' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'recycling_shipments' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "recyclings" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....tgrelid = C.OID AND C.relname = 'recyclings' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'recyclings' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "report_logs" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'report_logs' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'report_logs' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "resources" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...T.tgrelid = C.OID AND C.relname = 'resources' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'resources' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "resources_volunteer_default_events" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elname = 'resources_volunteer_default_events' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'resources_volunteer_default_events' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "resources_volunteer_events" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... AND C.relname = 'resources_volunteer_events' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'resources_volunteer_events' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "return_policies" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'return_policies' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'return_policies' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "roles" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'roles' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'roles' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "roles_users" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'roles_users' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'roles_users' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "rosters" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... (T.tgrelid = C.OID AND C.relname = 'rosters' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'rosters' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "rosters_skeds" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'rosters_skeds' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'rosters_skeds' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "rr_items" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'rr_items' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'rr_items' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "rr_sets" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... (T.tgrelid = C.OID AND C.relname = 'rr_sets' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'rr_sets' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "sale_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....tgrelid = C.OID AND C.relname = 'sale_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'sale_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "sales" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'sales' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'sales' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "schedules" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...T.tgrelid = C.OID AND C.relname = 'schedules' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'schedules' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "schema_info" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'schema_info' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'schema_info' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "sessions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'sessions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'sessions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "shift_footnotes" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'shift_footnotes' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'shift_footnotes' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...N (T.tgrelid = C.OID AND C.relname = 'shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "skedjulnator_accesses" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...C.OID AND C.relname = 'skedjulnator_accesses' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'skedjulnator_accesses' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "skeds" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'skeds' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'skeds' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "spec_sheet_question_conditions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.relname = 'spec_sheet_question_conditions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'spec_sheet_question_conditions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "spec_sheet_questions" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'spec_sheet_questions' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'spec_sheet_questions' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "spec_sheet_values" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...d = C.OID AND C.relname = 'spec_sheet_values' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'spec_sheet_values' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "spec_sheets" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'spec_sheets' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'spec_sheets' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "standard_shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'standard_shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'standard_shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "store_credits" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'store_credits' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'store_credits' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "store_pricings" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...elid = C.OID AND C.relname = 'store_pricings' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'store_pricings' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "systems" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... (T.tgrelid = C.OID AND C.relname = 'systems' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'systems' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "tech_support_notes" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... = C.OID AND C.relname = 'tech_support_notes' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'tech_support_notes' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "till_adjustments" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'till_adjustments' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'till_adjustments' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "till_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ....tgrelid = C.OID AND C.relname = 'till_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'till_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "users" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ON (T.tgrelid = C.OID AND C.relname = 'users' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'users' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "vacations" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...T.tgrelid = C.OID AND C.relname = 'vacations' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'vacations' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_default_events" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ID AND C.relname = 'volunteer_default_events' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_default_events' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_default_shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...ID AND C.relname = 'volunteer_default_shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_default_shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_events" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'volunteer_events' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_events' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'volunteer_shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_task_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'volunteer_task_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_task_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "volunteer_tasks" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...lid = C.OID AND C.relname = 'volunteer_tasks' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'volunteer_tasks' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "warranty_lengths" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...id = C.OID AND C.relname = 'warranty_lengths' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'warranty_lengths' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "wc_categories" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'wc_categories' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'wc_categories' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "weekdays" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...(T.tgrelid = C.OID AND C.relname = 'weekdays' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'weekdays' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "work_shift_footnotes" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'work_shift_footnotes' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'work_shift_footnotes' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "work_shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...tgrelid = C.OID AND C.relname = 'work_shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'work_shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "worked_shifts" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...relid = C.OID AND C.relname = 'worked_shifts' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'worked_shifts' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "worker_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ...grelid = C.OID AND C.relname = 'worker_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'worker_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "workers" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... (T.tgrelid = C.OID AND C.relname = 'workers' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'workers' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

# Could not dump table "workers_worker_types" because of following ActiveRecord::StatementInvalid
#   PG::Error: ERROR:  column t.tgisconstraint does not exist
LINE 3: ... C.OID AND C.relname = 'workers_worker_types' AND T.tgiscons...
                                                             ^
:           SELECT T.oid, C.relname, T.tgname, T.tgtype, P.proname
            FROM pg_trigger T
            JOIN pg_class   C ON (T.tgrelid = C.OID AND C.relname = 'workers_worker_types' AND T.tgisconstraint = 'f')
            JOIN pg_proc    P ON (T.tgfoid = P.OID)

  add_foreign_key "actions", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "actions_created_by_fkey"
  add_foreign_key "actions", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "actions_updated_by_fkey"

  add_foreign_key "assignments", ["attendance_type_id"], "attendance_types", ["id"], :on_delete => :restrict, :name => "assignments_attendance_type_id_fkey"
  add_foreign_key "assignments", ["call_status_type_id"], "call_status_types", ["id"], :name => "assignments_call_status_type_id_fkey"
  add_foreign_key "assignments", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "assignments_contact_id_fkey"
  add_foreign_key "assignments", ["volunteer_shift_id"], "volunteer_shifts", ["id"], :on_delete => :cascade, :name => "assignments_volunteer_shift_id_fkey"

  add_foreign_key "builder_tasks", ["action_id"], "actions", ["id"], :name => "builder_tasks_action_id_fkey"
  add_foreign_key "builder_tasks", ["cashier_signed_off_by"], "users", ["id"], :on_delete => :restrict, :name => "builder_tasks_cashier_signed_off_by_fkey"
  add_foreign_key "builder_tasks", ["contact_id"], "contacts", ["id"], :name => "builder_tasks_contact_id_fkey"

  add_foreign_key "contact_duplicates", ["contact_id"], "contacts", ["id"], :name => "contact_duplicates_contact_id_fkey"

  add_foreign_key "contact_method_types", ["parent_id"], "contact_method_types", ["id"], :on_delete => :set_null, :name => "contact_method_types_parent_id_fk"

  add_foreign_key "contact_methods", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "contact_methods_contact_id_fk"
  add_foreign_key "contact_methods", ["contact_method_type_id"], "contact_method_types", ["id"], :on_delete => :restrict, :name => "contact_methods_contact_method_type_fk"

  add_foreign_key "contact_types_contacts", ["contact_type_id"], "contact_types", ["id"], :on_delete => :restrict, :name => "contact_types_contacts_contact_types_contacts_fk"
  add_foreign_key "contact_types_contacts", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "contact_types_contacts_contacts_fk"

  add_foreign_key "contact_volunteer_task_type_counts", ["contact_id"], "contacts", ["id"], :name => "contact_volunteer_task_type_counts_contact_id_fkey"

  add_foreign_key "contacts", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_cashier_created_by_fkey"
  add_foreign_key "contacts", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_cashier_updated_by_fkey"
  add_foreign_key "contacts", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "contacts_contract_id_fkey"
  add_foreign_key "contacts", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_created_by_fkey"
  add_foreign_key "contacts", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "contacts_updated_by_fkey"

  add_foreign_key "contacts_mailings", ["contact_id"], "contacts", ["id"], :name => "contacts_mailings_contact_id_fkey"
  add_foreign_key "contacts_mailings", ["mailing_id"], "mailings", ["id"], :name => "contacts_mailings_mailing_id_fkey"

  add_foreign_key "default_assignments", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "default_assignments_contact_id_fkey"
  add_foreign_key "default_assignments", ["volunteer_default_shift_id"], "volunteer_default_shifts", ["id"], :on_delete => :cascade, :name => "default_assignments_volunteer_default_shift_id_fkey"

  add_foreign_key "disbursements", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "disbursements_cashier_created_by_fkey"
  add_foreign_key "disbursements", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "disbursements_cashier_updated_by_fkey"
  add_foreign_key "disbursements", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "disbursements_contacts_fk"
  add_foreign_key "disbursements", ["disbursement_type_id"], "disbursement_types", ["id"], :on_delete => :restrict, :name => "disbursements_disbursements_type_id_fk"

  add_foreign_key "disciplinary_action_areas_disciplinary_actions", ["disciplinary_action_area_id"], "disciplinary_action_areas", ["id"], :on_delete => :cascade, :name => "disciplinary_action_areas_disc_disciplinary_action_area_id_fkey"
  add_foreign_key "disciplinary_action_areas_disciplinary_actions", ["disciplinary_action_id"], "disciplinary_actions", ["id"], :on_delete => :cascade, :name => "disciplinary_action_areas_disciplin_disciplinary_action_id_fkey"

  add_foreign_key "disciplinary_actions", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "disciplinary_actions_cashier_created_by_fkey"
  add_foreign_key "disciplinary_actions", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "disciplinary_actions_cashier_updated_by_fkey"
  add_foreign_key "disciplinary_actions", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "disciplinary_actions_contact_id_fkey"
  add_foreign_key "disciplinary_actions", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "disciplinary_actions_created_by_fkey"
  add_foreign_key "disciplinary_actions", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "disciplinary_actions_updated_by_fkey"

  add_foreign_key "disktest_batch_drives", ["disktest_batch_id"], "disktest_batches", ["id"], :on_delete => :cascade, :name => "disktest_batch_drives_disktest_batch_id_fkey"
  add_foreign_key "disktest_batch_drives", ["disktest_run_id"], "disktest_runs", ["id"], :on_delete => :restrict, :name => "disktest_batch_drives_disktest_run_id_fkey"
  add_foreign_key "disktest_batch_drives", ["user_destroyed_by_id"], "users", ["id"], :on_delete => :restrict, :name => "disktest_batch_drives_user_destroyed_by_id_fkey"

  add_foreign_key "disktest_batches", ["contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "disktest_batches_contact_id_fkey"
  add_foreign_key "disktest_batches", ["user_finalized_by_id"], "users", ["id"], :on_delete => :restrict, :name => "disktest_batches_user_finalized_by_id_fkey"

  add_foreign_key "donations", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_cashier_created_by_fkey"
  add_foreign_key "donations", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_cashier_updated_by_fkey"
  add_foreign_key "donations", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "donations_contacts_fk"
  add_foreign_key "donations", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "donations_contract_id_fkey"
  add_foreign_key "donations", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_created_by_fkey"
  add_foreign_key "donations", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "donations_updated_by_fkey"

  add_foreign_key "gizmo_contexts_gizmo_types", ["gizmo_context_id"], "gizmo_contexts", ["id"], :on_delete => :cascade, :name => "gizmo_contexts_gizmo_types_gizmo_contexts_fk"
  add_foreign_key "gizmo_contexts_gizmo_types", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :cascade, :name => "gizmo_contexts_gizmo_types_gizmo_types_fk"

  add_foreign_key "gizmo_events", ["disbursement_id"], "disbursements", ["id"], :name => "gizmo_events_disbursements_fk"
  add_foreign_key "gizmo_events", ["discount_percentage_id"], "discount_percentages", ["id"], :on_delete => :restrict, :name => "gizmo_events_discount_percentage_id_fkey"
  add_foreign_key "gizmo_events", ["donation_id"], "donations", ["id"], :on_delete => :set_null, :name => "gizmo_events_donations_fk"
  add_foreign_key "gizmo_events", ["gizmo_context_id"], "gizmo_contexts", ["id"], :on_delete => :restrict, :name => "gizmo_events_gizmo_contexts_fk"
  add_foreign_key "gizmo_events", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :restrict, :name => "gizmo_events_gizmo_types_fk"
  add_foreign_key "gizmo_events", ["recycling_contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "gizmo_events_recycling_contract_id_fkey"
  add_foreign_key "gizmo_events", ["recycling_id"], "recyclings", ["id"], :on_delete => :set_null, :name => "gizmo_events_recyclings_fk"
  add_foreign_key "gizmo_events", ["return_disbursement_id"], "disbursements", ["id"], :on_delete => :restrict, :name => "gizmo_events_return_disbursement_id_fk"
  add_foreign_key "gizmo_events", ["return_sale_id"], "sales", ["id"], :on_delete => :restrict, :name => "gizmo_events_return_sale_id_fk"
  add_foreign_key "gizmo_events", ["return_store_credit_id"], "store_credits", ["id"], :on_delete => :restrict, :name => "gizmo_events_return_store_credit_id_fkey"
  add_foreign_key "gizmo_events", ["sale_id"], "sales", ["id"], :on_delete => :set_null, :name => "gizmo_events_sales_fk"
  add_foreign_key "gizmo_events", ["system_id"], "systems", ["id"], :on_delete => :restrict, :name => "gizmo_events_system_id_fkey"
  add_foreign_key "gizmo_events", ["store_pricing_id"], "store_pricings", ["id"], :on_delete => :set_null, :name => "gizmo_events_store_pricing_id_fkey"

  add_foreign_key "gizmo_returns", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "gizmo_returns_cashier_created_by_fkey"
  add_foreign_key "gizmo_returns", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "gizmo_returns_cashier_updated_by_fkey"
  add_foreign_key "gizmo_returns", ["contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "gizmo_returns_contact_id_fkey"
  add_foreign_key "gizmo_returns", ["payment_method_id"], "payment_methods", ["id"], :on_delete => :restrict, :name => "gizmo_returns_payment_method_id_fkey"

  add_foreign_key "gizmo_type_groups_gizmo_types", ["gizmo_type_group_id"], "gizmo_type_groups", ["id"], :on_delete => :cascade, :name => "gizmo_type_groups_gizmo_types_gizmo_type_group_id_fkey"
  add_foreign_key "gizmo_type_groups_gizmo_types", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :cascade, :name => "gizmo_type_groups_gizmo_types_gizmo_type_id_fkey"

  add_foreign_key "gizmo_types", ["gizmo_category_id"], "gizmo_categories", ["id"], :name => "gizmo_types_gizmo_categories_fk"
  add_foreign_key "gizmo_types", ["return_policy_id"], "return_policies", ["id"], :name => "gizmo_types_return_policy_id_fkey"

  add_foreign_key "holidays", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "holidays_schedules"
  add_foreign_key "holidays", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "holidays_weekdays"

  add_foreign_key "jobs", ["income_stream_id"], "income_streams", ["id"], :on_delete => :restrict, :name => "jobs_income_stream_id_fkey"
  add_foreign_key "jobs", ["program_id"], "programs", ["id"], :on_delete => :restrict, :name => "jobs_program_id_fkey"
  add_foreign_key "jobs", ["wc_category_id"], "wc_categories", ["id"], :on_delete => :restrict, :name => "jobs_wc_category_id_fkey"

  add_foreign_key "mailings", ["created_by"], "contacts", ["id"], :name => "mailings_created_by_fkey"
  add_foreign_key "mailings", ["updated_by"], "contacts", ["id"], :name => "mailings_updated_by_fkey"

  add_foreign_key "meeting_minders", ["meeting_id"], "shifts", ["id"], :on_delete => :cascade, :name => "meeting_minders_meeting_id_fkey"

  add_foreign_key "meetings_workers", ["meeting_id"], "shifts", ["id"], :on_delete => :cascade, :name => "meetings_workers_meetings"
  add_foreign_key "meetings_workers", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "meetings_workers_workers"

  add_foreign_key "notes", ["contact_id"], "contacts", ["id"], :name => "notes_contact_id_fkey"
  add_foreign_key "notes", ["system_id"], "systems", ["id"], :name => "notes_system_id_fkey"

  add_foreign_key "payments", ["donation_id"], "donations", ["id"], :on_delete => :cascade, :name => "payments_donation_id_fk"
  add_foreign_key "payments", ["payment_method_id"], "payment_methods", ["id"], :on_delete => :restrict, :name => "payments_payment_methods_fk"
  add_foreign_key "payments", ["sale_id"], "sales", ["id"], :name => "payments_sale_txn_id_fkey"

  add_foreign_key "points_trades", ["from_contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "points_trades_from_contact_id_fkey"
  add_foreign_key "points_trades", ["to_contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "points_trades_to_contact_id_fkey"

  add_foreign_key "pricing_types_types", ["type_id"], "types", ["id"], :on_delete => :cascade, :name => "pricing_types_types_type_id_fkey"

  add_foreign_key "recycling_shipments", ["contact_id"], "contacts", ["id"], :on_delete => :restrict, :name => "recycling_shipments_contact_id_fkey"

  add_foreign_key "recyclings", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "recyclings_cashier_created_by_fkey"
  add_foreign_key "recyclings", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "recyclings_cashier_updated_by_fkey"

  add_foreign_key "resources_volunteer_default_events", ["volunteer_default_event_id"], "volunteer_default_events", ["id"], :on_delete => :cascade, :name => "resources_volunteer_default_eve_volunteer_default_event_id_fkey"
  add_foreign_key "resources_volunteer_default_events", ["resource_id"], "resources", ["id"], :on_delete => :restrict, :name => "resources_volunteer_default_events_resource_id_fkey"
  add_foreign_key "resources_volunteer_default_events", ["roster_id"], "rosters", ["id"], :on_delete => :restrict, :name => "resources_volunteer_default_events_roster_id_fkey"

  add_foreign_key "resources_volunteer_events", ["resource_id"], "resources", ["id"], :on_delete => :restrict, :name => "resources_volunteer_events_resource_id_fkey"
  add_foreign_key "resources_volunteer_events", ["resources_volunteer_default_event_id"], "resources_volunteer_default_events", ["id"], :on_delete => :set_null, :name => "resources_volunteer_events_resources_volunteer_default_eve_fkey"
  add_foreign_key "resources_volunteer_events", ["roster_id"], "rosters", ["id"], :on_delete => :restrict, :name => "resources_volunteer_events_roster_id_fkey"
  add_foreign_key "resources_volunteer_events", ["volunteer_event_id"], "volunteer_events", ["id"], :on_delete => :cascade, :name => "resources_volunteer_events_volunteer_event_id_fkey"

  add_foreign_key "roles_users", ["role_id"], "roles", ["id"], :on_delete => :cascade, :name => "roles_users_role_id_fkey"
  add_foreign_key "roles_users", ["user_id"], "users", ["id"], :on_delete => :cascade, :name => "roles_users_user_id_fkey"

  add_foreign_key "rosters", ["contact_type_id"], "contact_types", ["id"], :on_delete => :set_null, :name => "rosters_contact_type_id_fkey"
  add_foreign_key "rosters", ["restrict_from_sked_id"], "skeds", ["id"], :on_delete => :restrict, :name => "rosters_restrict_from_sked_id_fkey"

  add_foreign_key "rosters_skeds", ["roster_id"], "rosters", ["id"], :on_delete => :cascade, :name => "rosters_skeds_roster_id_fkey"
  add_foreign_key "rosters_skeds", ["sked_id"], "skeds", ["id"], :on_delete => :cascade, :name => "rosters_skeds_sked_id_fkey"

  add_foreign_key "rr_items", ["rr_set_id"], "rr_sets", ["id"], :on_delete => :cascade, :name => "rr_items_rr_sets"

  add_foreign_key "sales", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_cashier_created_by_fkey"
  add_foreign_key "sales", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_cashier_updated_by_fkey"
  add_foreign_key "sales", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "sales_contacts_fk"
  add_foreign_key "sales", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_created_by_fkey"
  add_foreign_key "sales", ["discount_name_id"], "discount_names", ["id"], :on_delete => :restrict, :name => "sales_discount_name_id_fkey"
  add_foreign_key "sales", ["discount_percentage_id"], "discount_percentages", ["id"], :on_delete => :restrict, :name => "sales_discount_percentage_id_fkey"
  add_foreign_key "sales", ["sale_type_id"], "sale_types", ["id"], :name => "sales_sale_type_id_fkey"
  add_foreign_key "sales", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "sales_updated_by_fkey"

  add_foreign_key "shift_footnotes", ["schedule_id"], "schedules", ["id"], :name => "shift_footnotes_schedule_id_fkey"
  add_foreign_key "shift_footnotes", ["weekday_id"], "weekdays", ["id"], :name => "shift_footnotes_weekday_id_fkey"

  add_foreign_key "shifts", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "shifts_created_by_fkey"
  add_foreign_key "shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "shifts_jobs"
  add_foreign_key "shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "shifts_schedules"
  add_foreign_key "shifts", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "shifts_updated_by_fkey"
  add_foreign_key "shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "shifts_weekdays"
  add_foreign_key "shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "shifts_workers"

  add_foreign_key "skedjulnator_accesses", ["user_id"], "users", ["id"], :on_delete => :cascade, :name => "skedjulnator_accesses_user_id_fkey"

  add_foreign_key "spec_sheet_question_conditions", ["spec_sheet_question_id"], "spec_sheet_questions", ["id"], :on_delete => :restrict, :name => "spec_sheet_question_conditions_spec_sheet_question_id_fkey"

  add_foreign_key "spec_sheet_values", ["spec_sheet_id"], "spec_sheets", ["id"], :on_delete => :cascade, :name => "spec_sheet_values_spec_sheet_id_fkey"
  add_foreign_key "spec_sheet_values", ["spec_sheet_question_id"], "spec_sheet_questions", ["id"], :on_delete => :cascade, :name => "spec_sheet_values_spec_sheet_question_id_fkey"

  add_foreign_key "spec_sheets", ["builder_task_id"], "builder_tasks", ["id"], :name => "spec_sheets_builder_task_id_fkey"
  add_foreign_key "spec_sheets", ["system_id"], "systems", ["id"], :name => "spec_sheets_system_id_fkey"
  add_foreign_key "spec_sheets", ["type_id"], "types", ["id"], :name => "spec_sheets_type_id_fkey"

  add_foreign_key "standard_shifts", ["job_id"], "jobs", ["id"], :on_delete => :cascade, :name => "standard_shifts_jobs"
  add_foreign_key "standard_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :cascade, :name => "standard_shifts_schedules"
  add_foreign_key "standard_shifts", ["weekday_id"], "weekdays", ["id"], :on_delete => :set_null, :name => "standard_shifts_weekdays"
  add_foreign_key "standard_shifts", ["worker_id"], "workers", ["id"], :on_delete => :set_null, :name => "standard_shifts_workers"

  add_foreign_key "store_credits", ["gizmo_event_id"], "gizmo_events", ["id"], :on_delete => :cascade, :name => "store_credits_gizmo_event_id_fkey"
  add_foreign_key "store_credits", ["gizmo_return_id"], "gizmo_returns", ["id"], :on_delete => :cascade, :name => "store_credits_gizmo_return_id_fkey"
  add_foreign_key "store_credits", ["payment_id"], "payments", ["id"], :on_delete => :set_null, :name => "store_credits_payment_id_fkey"

  add_foreign_key "store_pricings", ["system_id"], "systems", ["id"], :on_delete => :cascade, :name => "store_pricings_system_id_fkey"
  add_foreign_key "store_pricings", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :restrict, :name => "store_pricings_gizmo_type_id_fkey"

  add_foreign_key "systems", ["contract_id"], "contracts", ["id"], :on_delete => :restrict, :name => "systems_contract_id_fkey"
  add_foreign_key "systems", ["previous_id"], "systems", ["id"], :name => "systems_previous_id_fkey"

  add_foreign_key "tech_support_notes", ["contact_id"], "contacts", ["id"], :on_delete => :cascade, :name => "tech_support_notes_contact_id_fkey"
  add_foreign_key "tech_support_notes", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "tech_support_notes_created_by_fkey"
  add_foreign_key "tech_support_notes", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "tech_support_notes_updated_by_fkey"

  add_foreign_key "till_adjustments", ["till_type_id"], "till_types", ["id"], :on_delete => :restrict, :name => "till_adjustments_till_type_id_fkey"

  add_foreign_key "types", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "types_created_by_fkey"
  add_foreign_key "types", ["gizmo_type_id"], "gizmo_types", ["id"], :on_delete => :restrict, :name => "types_gizmo_type_id_fkey"
  add_foreign_key "types", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "types_updated_by_fkey"

  add_foreign_key "users", ["contact_id"], "contacts", ["id"], :name => "users_contacts_fk"
  add_foreign_key "users", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "users_created_by_fkey"
  add_foreign_key "users", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "users_updated_by_fkey"

  add_foreign_key "vacations", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "vacations_created_by_fkey"
  add_foreign_key "vacations", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "vacations_updated_by_fkey"
  add_foreign_key "vacations", ["worker_id"], "workers", ["id"], :on_delete => :cascade, :name => "vacations_workers"

  add_foreign_key "volunteer_default_shifts", ["program_id"], "programs", ["id"], :on_delete => :set_null, :name => "volunteer_default_shifts_program_id_fkey"
  add_foreign_key "volunteer_default_shifts", ["roster_id"], "rosters", ["id"], :on_delete => :cascade, :name => "volunteer_default_shifts_roster_id_fkey"
  add_foreign_key "volunteer_default_shifts", ["volunteer_default_event_id"], "volunteer_default_events", ["id"], :on_delete => :cascade, :name => "volunteer_default_shifts_volunteer_default_event_id_fkey"
  add_foreign_key "volunteer_default_shifts", ["volunteer_task_type_id"], "volunteer_task_types", ["id"], :on_delete => :restrict, :name => "volunteer_default_shifts_volunteer_task_type_id_fkey"

  add_foreign_key "volunteer_events", ["volunteer_default_event_id"], "volunteer_default_events", ["id"], :on_delete => :set_null, :name => "volunteer_events_volunteer_default_event_id_fkey"

  add_foreign_key "volunteer_shifts", ["program_id"], "programs", ["id"], :on_delete => :set_null, :name => "volunteer_shifts_program_id_fkey"
  add_foreign_key "volunteer_shifts", ["roster_id"], "rosters", ["id"], :on_delete => :cascade, :name => "volunteer_shifts_roster_id_fkey"
  add_foreign_key "volunteer_shifts", ["volunteer_default_shift_id"], "volunteer_default_shifts", ["id"], :on_delete => :set_null, :name => "volunteer_shifts_volunteer_default_shift_id_fkey"
  add_foreign_key "volunteer_shifts", ["volunteer_event_id"], "volunteer_events", ["id"], :on_delete => :cascade, :name => "volunteer_shifts_volunteer_event_id_fkey"
  add_foreign_key "volunteer_shifts", ["volunteer_event_id"], "volunteer_events", ["id"], :on_delete => :cascade, :name => "volunteer_shifts_volunteer_event_id_fkey1"
  add_foreign_key "volunteer_shifts", ["volunteer_task_type_id"], "volunteer_task_types", ["id"], :on_delete => :restrict, :name => "volunteer_shifts_volunteer_task_type_id_fkey"

  add_foreign_key "volunteer_task_types", ["program_id"], "programs", ["id"], :on_delete => :restrict, :name => "volunteer_task_types_program_id_fkey"

  add_foreign_key "volunteer_tasks", ["cashier_created_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_cashier_created_by_fkey"
  add_foreign_key "volunteer_tasks", ["cashier_updated_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_cashier_updated_by_fkey"
  add_foreign_key "volunteer_tasks", ["community_service_type_id"], "community_service_types", ["id"], :on_delete => :set_null, :name => "volunteer_tasks_community_service_type_id_fkey"
  add_foreign_key "volunteer_tasks", ["contact_id"], "contacts", ["id"], :on_delete => :set_null, :name => "volunteer_tasks_contacts_fk"
  add_foreign_key "volunteer_tasks", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_created_by_fkey"
  add_foreign_key "volunteer_tasks", ["program_id"], "programs", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_program_id_fkey"
  add_foreign_key "volunteer_tasks", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_updated_by_fkey"
  add_foreign_key "volunteer_tasks", ["volunteer_task_type_id"], "volunteer_task_types", ["id"], :on_delete => :restrict, :name => "volunteer_tasks_volunteer_task_type_id_fk"

  add_foreign_key "work_shifts", ["created_by"], "users", ["id"], :on_delete => :restrict, :name => "work_shifts_created_by_fkey"
  add_foreign_key "work_shifts", ["job_id"], "jobs", ["id"], :on_delete => :set_null, :name => "work_shifts_jobs"
  add_foreign_key "work_shifts", ["schedule_id"], "schedules", ["id"], :on_delete => :set_null, :name => "work_shifts_schedules"
  add_foreign_key "work_shifts", ["updated_by"], "users", ["id"], :on_delete => :restrict, :name => "work_shifts_updated_by_fkey"
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
