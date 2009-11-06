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
-- Name: frequency_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('frequency_types_id_seq', 50, false);


--
-- Data for Name: frequency_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE frequency_types DISABLE TRIGGER ALL;

COPY frequency_types (id, name, description) FROM stdin;
1	once	does not repeat
2	daily	happens every day
3	weekly	happens every Nth week on a particular weekday
4	monthly	happens every Nth month on a particular day of the month
5	dowinmonth	happens every Nth day of week in every Nth month 
6	yearly	happens on a given date each year
7	dowinyear	happens every Nth day of week in a given month every year
\.


ALTER TABLE frequency_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

