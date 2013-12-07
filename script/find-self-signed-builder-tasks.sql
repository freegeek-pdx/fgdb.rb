#!/bin/sh
exec ruby `dirname $0`/sql_runner $0 "$@"

SELECT users.contact_id AS builder_id, contacts.first_name || ' ' || contacts.surname AS builder_name, actions.name AS builder_action, spec_sheets.system_id, builder_tasks.created_at, builder_tasks.updated_at FROM builder_tasks JOIN users ON users.contact_id = builder_tasks.contact_id JOIN contacts on users.contact_id = contacts.id LEFT OUTER JOIN spec_sheets on spec_sheets.builder_task_id = builder_tasks.id JOIN actions ON builder_tasks.action_id = actions.id WHERE cashier_signed_off_by = users.id AND EXTRACT(month FROM builder_tasks.updated_at) = EXTRACT(month FROM now()::date - 20) AND EXTRACT(year FROM builder_tasks.updated_at) = EXTRACT(year FROM now()::date - 20) ORDER BY builder_tasks.created_at;
