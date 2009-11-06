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
-- Name: gizmo_contexts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gizmo_contexts_id_seq', 5, true);


--
-- Data for Name: gizmo_contexts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_contexts DISABLE TRIGGER ALL;

COPY gizmo_contexts (id, description, lock_version, updated_at, created_at, name) FROM stdin;
4	disbursement	2	2007-08-10 18:26:17	2006-10-19 09:45:57	disbursement
1	donation	1	2008-07-25 21:48:34.860361	2006-10-10 12:11:44	donation
3	recycling	0	2006-10-19 09:45:49	2006-10-19 09:45:49	recycling
2	sale	0	2006-10-10 12:11:56	2006-10-10 12:11:56	sale
5	return	0	2009-08-12 01:46:00.963953	2009-08-12 01:46:00.963953	gizmo_return
\.


ALTER TABLE gizmo_contexts ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

