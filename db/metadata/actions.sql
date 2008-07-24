--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('actions_id_seq', 1, false);


--
-- Data for Name: actions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE actions DISABLE TRIGGER ALL;

COPY actions (id, name, lock_version, updated_at, created_at, created_by, updated_by) FROM stdin;
\.


ALTER TABLE actions ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

