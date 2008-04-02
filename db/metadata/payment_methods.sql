--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fgdb
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('payment_methods', 'id'), 6, true);


--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: public; Owner: fgdb
--

ALTER TABLE payment_methods DISABLE TRIGGER ALL;

COPY payment_methods (id, description, lock_version, updated_at, created_at) FROM stdin;
1	cash	0	2006-09-25 13:12:18-07	2006-09-25 13:12:18-07
2	check	0	2006-09-25 13:12:23-07	2006-09-25 13:12:23-07
3	credit	0	2006-11-21 13:41:18-08	2006-11-21 13:41:18-08
5	invoice	0	2007-01-31 21:16:39-08	2007-01-31 21:16:39-08
6	coupon	0	2007-12-11 17:43:33-08	2007-12-11 17:43:33-08
\.


ALTER TABLE payment_methods ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

