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
-- Name: holidays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('holidays_id_seq', 37, true);


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE holidays DISABLE TRIGGER ALL;

COPY holidays (id, name, holiday_date, is_all_day, start_time, end_time, frequency_type_id, schedule_id, weekday_id) FROM stdin;
30	Christmas	2010-12-25	t	08:00:00	08:00:00	6	1	6
31	Independence Day	2010-07-03	t	08:00:00	08:00:00	6	1	6
32	Labor Day	2010-09-04	t	08:00:00	08:00:00	6	1	6
33	May Day	2010-05-01	t	08:00:00	08:00:00	6	1	6
34	Memorial Day	2010-05-29	t	08:00:00	08:00:00	6	1	6
35	Thanksgiving	2010-11-25	t	08:00:00	08:00:00	6	1	4
36	Thanksgiving	2010-11-26	t	08:00:00	08:00:00	6	1	5
37	Thanksgiving	2010-11-27	t	08:00:00	08:00:00	6	1	6
9	Memorial Day	2008-05-24	t	\N	\N	6	1	6
12	Independence Day	2008-07-05	t	\N	\N	6	1	6
13	Labor Day	2008-08-30	t	\N	\N	6	1	6
15	Thanksgiving	2008-11-29	t	\N	\N	6	1	6
17	Thanksgiving	2008-11-27	t	\N	\N	6	1	4
14	Thanksgiving	2008-11-28	t	\N	\N	6	1	5
11	Independence Day	2008-07-04	t	\N	\N	6	1	5
16	Christmas	2008-12-25	t	\N	\N	6	1	4
8	May Day	2008-05-01	t	\N	\N	6	1	4
18	New Year's Day	2009-01-01	t	11:00:00	11:00:00	6	1	0
19	May Day	2009-05-01	t	\N	\N	6	1	5
20	Memorial Day	2009-05-23	t	\N	\N	6	1	6
21	Independence Day	2009-07-04	\N	\N	\N	6	1	6
22	Labor Day	2009-09-05	\N	\N	\N	6	1	6
23	Thanksgiving	2009-11-26	\N	\N	\N	6	1	4
24	Thanksgiving	2009-11-27	\N	\N	\N	6	1	5
25	Thanksgiving	2009-11-28	\N	\N	\N	6	1	6
26	Christmas	2009-12-25	\N	\N	\N	6	1	5
27	Christmas	2009-12-26	\N	\N	\N	6	1	6
28	New Years	2010-01-01	\N	\N	\N	6	1	5
29	New Years	2010-01-02	\N	\N	\N	6	1	6
\.


ALTER TABLE holidays ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

