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
-- Name: customizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('customizations_id_seq', 10, true);


--
-- Data for Name: customizations; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE customizations DISABLE TRIGGER ALL;

COPY customizations (id, key, value) FROM stdin;
1	time_resolution	15
2	day_start_display	09:00
3	day_end_display	17:00
4	hour_format	12
5	week_start	Sun
6	display_start	today
7	display_length	7
8	generate_start_day	Sun
9	generate_start_week	1
10	generate_length	14
\.


ALTER TABLE customizations ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

