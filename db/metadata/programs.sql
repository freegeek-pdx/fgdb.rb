--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: programs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('programs_id_seq', 10, true);


--
-- Data for Name: programs; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE programs DISABLE TRIGGER ALL;

COPY programs (id, name, description, created_at, updated_at, volunteer) FROM stdin;
3	altbuild	Advanced Build	2009-10-31 15:12:15.045528	2009-10-31 15:12:15.045528	f
4	reuse	Reuse and E-Waste Diversion	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527	f
5	access	Internet Access	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527	f
6	education	Job Training, Education, and Related Resources	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527	f
7	fundraising	Fundraising	2009-10-31 15:12:15.053527	2009-10-31 15:12:15.053527	f
8	overhead	Overhead	2009-10-31 15:12:15.053527	2009-10-31 15:12:15.053527	f
1	adoption	Adoption	2009-10-31 15:12:14.97353	2010-03-27 12:01:27.997399	t
2	build	Build	2009-10-31 15:12:15.045528	2010-03-27 12:01:28.0494	t
9	intern	Interns	2010-03-27 01:54:34.139835	2010-03-27 12:01:28.0574	t
10	other	Other	2010-03-27 01:54:34.42384	2010-03-27 12:01:28.0654	t
\.


ALTER TABLE programs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

