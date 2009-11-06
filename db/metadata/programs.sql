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
-- Name: programs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('programs_id_seq', 8, true);


--
-- Data for Name: programs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE programs DISABLE TRIGGER ALL;

COPY programs (id, name, description, created_at, updated_at) FROM stdin;
1	adoption	Adoption	2009-10-31 15:12:14.97353	2009-10-31 15:12:14.97353
2	build	Build	2009-10-31 15:12:15.045528	2009-10-31 15:12:15.045528
3	altbuild	Advanced Build	2009-10-31 15:12:15.045528	2009-10-31 15:12:15.045528
4	reuse	Reuse and E-Waste Diversion	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527
5	access	Internet Access	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527
6	education	Job Training, Education, and Related Resources	2009-10-31 15:12:15.049527	2009-10-31 15:12:15.049527
7	fundraising	Fundraising	2009-10-31 15:12:15.053527	2009-10-31 15:12:15.053527
8	overhead	Overhead	2009-10-31 15:12:15.053527	2009-10-31 15:12:15.053527
\.


ALTER TABLE programs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

