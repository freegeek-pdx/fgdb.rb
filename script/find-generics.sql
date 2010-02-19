#!/bin/sh
exec ruby `dirname $0`/sql_runner $0 "$@"

SELECT system_id AS id, systems.vendor, systems.model, systems.serial_number AS serial_number, max(spec_sheets.created_at) AS last_created, count(*) AS count FROM spec_sheets JOIN systems ON systems.id = system_id WHERE length(systems.serial_number) > 5 AND systems.serial_number NOT IN (SELECT value FROM generics) AND systems.vendor NOT IN (SELECT value FROM generics WHERE only_serial = 'f') AND systems.model NOT IN (SELECT value FROM generics WHERE only_serial = 'f') GROUP BY system_id, systems.vendor, systems.model, systems.serial_number HAVING count(*) > 5 ORDER by count DESC;
