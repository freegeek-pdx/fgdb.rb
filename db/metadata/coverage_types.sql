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
-- Name: coverage_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('coverage_types_id_seq', 50, false);


--
-- Data for Name: coverage_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE coverage_types DISABLE TRIGGER ALL;

COPY coverage_types (id, name, description) FROM stdin;
1	full	needs to be happening whenever we are open
2	anchored	needs to happen at a specific time
3	heavy	can happen whenever, but resists moving from scheduled time
4	light	can happen whenever and is more likely to float
5	floating	can happen whenever and is likely to float
\.


ALTER TABLE coverage_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

