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
-- Name: gizmo_typeattrs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gizmo_typeattrs_id_seq', 30, true);


--
-- Data for Name: gizmo_typeattrs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_typeattrs DISABLE TRIGGER ALL;

COPY gizmo_typeattrs (id, gizmo_type_id, gizmo_attr_id, is_required, validation_callback, lock_version, updated_at, created_at) FROM stdin;
14	13	3	t		0	2006-11-11 19:33:27	2006-11-11 19:33:27
15	17	3	t		1	2006-11-11 19:40:35	2006-11-11 19:33:42
17	1	2	t		1	2006-12-20 09:56:18	2006-11-11 19:38:07
22	19	10	t		0	2006-12-30 15:03:52	2006-12-30 15:03:52
23	20	10	t		0	2006-12-30 15:04:15	2006-12-30 15:04:15
24	21	10	t		0	2006-12-30 18:59:43	2006-12-30 18:59:43
26	38	10	t		0	2007-01-17 14:36:37	2007-01-17 14:36:37
27	13	10	t		2	2007-04-04 18:30:24	2007-01-24 16:30:53
25	31	10	t		2	2007-08-08 16:38:21	2007-01-02 10:35:40
28	46	10	t		0	2007-12-11 17:51:19	2007-12-11 17:51:19
29	45	3	t		0	2007-12-14 15:51:19	2007-12-14 15:51:19
30	13	11	t		0	2008-03-21 13:43:44	2008-03-21 13:43:44
\.


ALTER TABLE gizmo_typeattrs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

