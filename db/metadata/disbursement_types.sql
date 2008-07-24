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
-- Name: disbursement_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('disbursement_types_id_seq', 5, true);


--
-- Data for Name: disbursement_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE disbursement_types DISABLE TRIGGER ALL;

COPY disbursement_types (id, description, lock_version, updated_at, created_at) FROM stdin;
1	Adoption	0	2007-04-04 17:26:09	2007-04-04 17:25:00
2	Build	0	2007-04-04 17:26:16	2007-04-04 17:26:00
3	Hardware Grants	0	2007-04-04 17:26:28	2007-04-04 17:26:00
4	GAP	0	2007-04-04 17:26:37	2007-04-04 17:26:00
5	Staff	0	2007-04-04 17:26:45	2007-04-04 17:26:00
\.


ALTER TABLE disbursement_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

