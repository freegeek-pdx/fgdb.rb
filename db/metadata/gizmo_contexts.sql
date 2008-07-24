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

SELECT pg_catalog.setval('gizmo_contexts_id_seq', 4, true);


--
-- Data for Name: gizmo_contexts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_contexts DISABLE TRIGGER ALL;

COPY gizmo_contexts (id, name, lock_version, updated_at, created_at) FROM stdin;
1	donation	0	2006-10-10 12:11:44	2006-10-10 12:11:44
2	sale	0	2006-10-10 12:11:56	2006-10-10 12:11:56
3	recycling	0	2006-10-19 09:45:49	2006-10-19 09:45:49
4	disbursement	2	2007-08-10 18:26:17	2006-10-19 09:45:57
\.


ALTER TABLE gizmo_contexts ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

