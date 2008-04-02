--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: community_service_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fgdb
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('community_service_types', 'id'), 2, true);


--
-- Data for Name: community_service_types; Type: TABLE DATA; Schema: public; Owner: fgdb
--

ALTER TABLE community_service_types DISABLE TRIGGER ALL;

COPY community_service_types (id, description, hours_multiplier, lock_version, updated_at, created_at) FROM stdin;
1	school	1	0	2008-03-30 00:47:56.431011	2008-03-30 00:47:56.431011
2	punitive	0	0	2008-03-30 00:47:56.445477	2008-03-30 00:47:56.445477
\.


ALTER TABLE community_service_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

