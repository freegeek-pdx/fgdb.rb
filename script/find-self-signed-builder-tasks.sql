#!/bin/sh
exec ruby `dirname $0`/sql_runner $0 "$@"

SELECT users.contact_id, contacts.first_name || ' ' || contacts.surname, actions.name, spec_sheets.system_id, builder_tasks.created_at, builder_tasks.updated_at FROM builder_tasks JOIN users ON users.contact_id = builder_tasks.contact_id JOIN contacts on users.contact_id = contacts.id LEFT OUTER JOIN spec_sheets on spec_sheets.builder_task_id = builder_tasks.id JOIN actions ON builder_tasks.action_id = actions.id WHERE cashier_signed_off_by = users.id ORDER BY builder_tasks.created_at;
