--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: contact_method_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('contact_method_types_id_seq', 15, true);


--
-- Data for Name: contact_method_types; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE contact_method_types DISABLE TRIGGER ALL;

COPY contact_method_types (id, description, parent_id, lock_version, updated_at, created_at, name) FROM stdin;
3	work phone	1	1	2006-09-21 08:37:15	2006-09-20 07:38:55	work_phone
2	home phone	1	1	2006-09-21 08:31:45	2006-09-20 07:38:40	home_phone
13	liason	\N	0	2006-11-25 02:31:31	2006-11-25 02:31:31	liason
7	work email	5	1	2006-12-05 18:04:01	2006-09-20 07:40:07	work_email
6	home email	5	1	2006-09-21 08:40:22	2006-09-20 07:40:03	home_email
10	work fax	8	1	2006-12-05 18:04:19	2006-09-20 07:40:25	work_fax
4	cell phone	1	1	2006-12-05 18:03:51	2006-09-20 07:39:43	cell_phone
8	fax	\N	0	2006-09-20 07:40:14	2006-09-20 07:40:14	fax
1	phone	\N	0	2006-09-20 07:38:21	2006-09-20 07:38:21	phone
9	home fax	8	1	2006-12-05 18:04:11	2006-09-20 07:40:22	home_fax
14	emergency phone	1	0	2006-12-05 18:03:37	2006-12-05 18:03:37	emergency_phone
15	ip phone	1	0	2007-07-11 16:29:24	2007-07-11 16:29:24	ip_phone
5	email	\N	0	2006-09-20 07:39:55	2006-09-20 07:39:55	email
\.


ALTER TABLE contact_method_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

