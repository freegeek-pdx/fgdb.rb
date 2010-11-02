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
-- Name: income_streams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('income_streams_id_seq', 11, true);


--
-- Data for Name: income_streams; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE income_streams DISABLE TRIGGER ALL;

COPY income_streams (id, name, description, created_at, updated_at) FROM stdin;
1	admin	Administrative	2009-11-24 17:07:00.12028	2009-11-24 17:07:00.12028
2	frontdesk	Front Desk	2009-11-24 17:07:00.20429	2009-11-24 17:07:00.20429
3	recycling	Recycling	2009-11-24 17:07:00.20429	2009-11-24 17:07:00.20429
4	build	Build	2009-11-24 17:07:00.208291	2009-11-24 17:07:00.208291
5	advanced_testing	Advanced Testing	2009-11-24 17:07:00.208291	2009-11-24 17:07:00.208291
6	macs	Macintoshes	2009-11-24 17:07:00.208291	2009-11-24 17:07:00.208291
7	laptops	Laptops	2009-11-24 17:07:00.212291	2009-11-24 17:07:00.212291
8	printers	Printer Land	2009-11-24 17:07:00.212291	2009-11-24 17:07:00.212291
9	online_sales	Online Sales	2009-11-24 17:07:00.212291	2009-11-24 17:07:00.212291
10	mixed	Mixed Income	2009-11-24 17:07:00.216292	2009-11-24 17:07:00.216292
11	fundraising	Fundraising	2009-11-24 17:07:00.216292	2009-11-24 17:07:00.216292
\.


ALTER TABLE income_streams ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

