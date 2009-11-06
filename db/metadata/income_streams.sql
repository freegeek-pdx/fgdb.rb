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
-- Name: income_streams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('income_streams_id_seq', 1, false);


--
-- Data for Name: income_streams; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE income_streams DISABLE TRIGGER ALL;

COPY income_streams (id, name, description, created_at, updated_at) FROM stdin;
\.


ALTER TABLE income_streams ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

