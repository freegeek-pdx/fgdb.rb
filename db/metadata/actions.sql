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
-- Name: actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('actions_id_seq', 5, true);


--
-- Data for Name: actions; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE actions DISABLE TRIGGER ALL;

COPY actions (id, description, lock_version, updated_at, created_at, created_by, updated_by, name) FROM stdin;
2	quality checker	0	2007-12-08 16:44:49.662759	2007-12-08 16:44:49.662759	1	1	checker
4	build instructor	0	2007-12-20 12:07:15.756392	2007-12-20 12:07:15.756392	1	1	instructor
1	builder	1	2008-06-21 17:14:16.724105	2007-12-08 16:44:49.656799	1	1	builder
3	tech support	0	2007-12-08 16:44:49.66862	2007-12-08 16:44:49.66862	1	1	tech_support
\.


ALTER TABLE actions ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

