--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: gizmo_typeattrs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fgdb
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('gizmo_typeattrs', 'id'), 30, true);


--
-- Data for Name: gizmo_typeattrs; Type: TABLE DATA; Schema: public; Owner: fgdb
--

ALTER TABLE gizmo_typeattrs DISABLE TRIGGER ALL;

COPY gizmo_typeattrs (id, gizmo_type_id, gizmo_attr_id, is_required, validation_callback, lock_version, updated_at, created_at) FROM stdin;
14	13	3	t		0	2006-11-11 19:33:27-08	2006-11-11 19:33:27-08
15	17	3	t		1	2006-11-11 19:40:35-08	2006-11-11 19:33:42-08
17	1	2	t		1	2006-12-20 09:56:18-08	2006-11-11 19:38:07-08
22	19	10	t		0	2006-12-30 15:03:52-08	2006-12-30 15:03:52-08
23	20	10	t		0	2006-12-30 15:04:15-08	2006-12-30 15:04:15-08
24	21	10	t		0	2006-12-30 18:59:43-08	2006-12-30 18:59:43-08
26	38	10	t		0	2007-01-17 14:36:37-08	2007-01-17 14:36:37-08
27	13	10	t		2	2007-04-04 18:30:24-07	2007-01-24 16:30:53-08
25	31	10	t		2	2007-08-08 16:38:21-07	2007-01-02 10:35:40-08
28	46	10	t		0	2007-12-11 17:51:19-08	2007-12-11 17:51:19-08
29	45	3	t		0	2007-12-14 15:51:19-08	2007-12-14 15:51:19-08
30	13	11	t		0	2008-03-21 13:43:44-07	2008-03-21 13:43:44-07
\.


ALTER TABLE gizmo_typeattrs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

