#!/bin/sh
exec ruby `dirname $0`/sql_runner $0 "$@"

SELECT
now()::date -1 AS date,
'Front Desk' AS location,
COUNT(donations.id) AS count
FROM users
LEFT JOIN donations ON donations.cashier_created_by = users.id
LEFT JOIN contacts ON users.contact_id = contacts.id
WHERE donations.created_at::date = now()::date - 1
GROUP BY 1, 2;

SELECT
contacts.first_name, contacts.surname,
users.id, users.login, users.contact_id, COUNT(donations.id) AS count
FROM users
LEFT JOIN donations ON donations.cashier_created_by = users.id
LEFT JOIN contacts ON users.contact_id = contacts.id
WHERE donations.created_at::date = now()::date - 1
GROUP BY 1, 2, 3, 4, 5;


SELECT
now()::date - 1 AS date,
'Thrift Store' AS location,
COUNT(sales.id) AS count
FROM users
LEFT JOIN sales ON sales.cashier_created_by = users.id
LEFT JOIN contacts ON users.contact_id = contacts.id
WHERE sales.created_at::date = now()::date - 1
GROUP BY 1, 2;

SELECT
contacts.first_name, contacts.surname,
users.id, users.login, users.contact_id, COUNT(sales.id) AS count
FROM users
LEFT JOIN sales ON sales.cashier_created_by = users.id
LEFT JOIN contacts ON users.contact_id = contacts.id
WHERE sales.created_at::date = now()::date - 1
GROUP BY 1, 2, 3, 4, 5;
