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
-- Name: gizmo_attrs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gizmo_attrs_id_seq', 11, true);


--
-- Data for Name: gizmo_attrs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_attrs DISABLE TRIGGER ALL;

COPY gizmo_attrs (id, name, datatype, lock_version, updated_at, created_at) FROM stdin;
1	suggested_price	monetary	1	2006-11-07 13:28:31	2006-10-10 12:10:04
2	size	integer	1	2006-11-07 13:28:37	2006-10-10 12:10:33
3	unit_price	monetary	1	2006-11-07 13:28:46	2006-10-18 18:04:44
8	presumed_functional	boolean	1	2006-11-07 13:29:15	2006-11-01 13:05:01
9	extended_price	monetary	0	2006-11-18 13:34:57	2006-11-18 13:34:57
10	description	text	0	2006-12-30 15:03:20	2006-12-30 15:03:20
11	as_is	boolean	0	2008-03-21 13:43:13	2008-03-21 13:43:13
\.


ALTER TABLE gizmo_attrs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

