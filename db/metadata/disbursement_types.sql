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
-- Name: disbursement_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('disbursement_types_id_seq', 7, true);


--
-- Data for Name: disbursement_types; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE disbursement_types DISABLE TRIGGER ALL;

COPY disbursement_types (id, description, lock_version, updated_at, created_at, name) FROM stdin;
4	GAP	0	2007-04-04 17:26:37	2007-04-04 17:26:00	gap
1	Adoption	0	2007-04-04 17:26:09	2007-04-04 17:25:00	adoption
3	Hardware Grants	0	2007-04-04 17:26:28	2007-04-04 17:26:00	hardware_grants
2	Build	0	2007-04-04 17:26:16	2007-04-04 17:26:00	build
6	Replacement	0	2009-08-12 01:46:01.099959	2009-08-12 01:46:01.099959	replacement
5	Infrastructure	1	2010-11-06 00:52:32.762188	2007-04-04 17:26:00	infrastructure
7	Misc.	0	2011-01-29 01:06:13.779558	2011-01-29 01:06:13.779558	misc
\.


ALTER TABLE disbursement_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

