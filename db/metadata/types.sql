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
-- Name: types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('types_id_seq', 9, true);


--
-- Data for Name: types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE types DISABLE TRIGGER ALL;

COPY types (id, name, lock_version, updated_at, created_at, created_by, updated_by) FROM stdin;
1	regular	0	\N	\N	1	1
2	freekbox	0	\N	\N	1	1
3	grantbox	0	\N	\N	1	1
4	laptop	0	\N	\N	1	1
5	high end	0	\N	\N	1	1
6	infrastructure	0	\N	\N	1	1
7	server	0	\N	\N	1	1
8	miscellaneous	0	\N	\N	1	1
9	apple	0	\N	\N	1	1
\.


ALTER TABLE types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

