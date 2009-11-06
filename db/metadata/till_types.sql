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
-- Name: till_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('till_types_id_seq', 3, true);


--
-- Data for Name: till_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE till_types DISABLE TRIGGER ALL;

COPY till_types (id, name, created_at, updated_at, description) FROM stdin;
1	TS	2009-08-12 18:23:00.467832	2009-08-12 18:23:00.467832	Thrift Store
2	FD	2009-08-12 18:23:00.563836	2009-08-12 18:23:00.563836	Front Desk
3	XX	2009-08-12 18:23:00.575837	2009-08-12 18:23:00.575837	Misc.
\.


ALTER TABLE till_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

