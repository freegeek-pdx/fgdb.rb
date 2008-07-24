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
-- Name: gizmo_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gizmo_categories_id_seq', 4, true);


--
-- Data for Name: gizmo_categories; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_categories DISABLE TRIGGER ALL;

COPY gizmo_categories (id, description) FROM stdin;
1	System
2	Monitor
3	Printer
4	Misc
\.


ALTER TABLE gizmo_categories ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

