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
-- Name: volunteer_task_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('volunteer_task_types_id_seq', 59, true);


--
-- Data for Name: volunteer_task_types; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE volunteer_task_types DISABLE TRIGGER ALL;

COPY volunteer_task_types (id, description, hours_multiplier, instantiable, lock_version, updated_at, created_at, name, effective_on, ineffective_on, program_id) FROM stdin;
56	monitors	1.000	t	3	2010-03-27 01:54:35.215853	2006-12-13 10:46:55	monitors	2009-10-02 00:00:00	\N	1
57	A/V	1.000	t	1	2010-03-27 01:54:35.227853	2010-02-19 23:43:53.706732	av	2009-10-02 22:40:21.818428	\N	2
58	Library	1.000	t	1	2010-03-27 01:54:35.243853	2010-02-19 23:43:53.730732	library	2009-10-02 22:40:21.818428	\N	10
32	slacking	0.000	t	1	2010-03-27 01:54:34.695844	2006-12-13 21:14:14	slacking	\N	\N	10
31	massage	4.000	t	1	2010-03-27 01:54:34.711845	2006-12-13 11:04:35	massage	\N	\N	10
42	misc	1.000	t	2	2010-03-27 01:54:34.727845	2006-12-30 08:40:54	misc	\N	\N	10
47	repair	1.000	t	1	2010-03-27 01:54:34.739845	2006-12-30 08:40:54.425307	repair	\N	\N	2
30	teaching	1.000	t	1	2010-03-27 01:54:34.755845	2006-12-13 11:04:23	teaching	\N	\N	10
28	receiving	1.000	t	1	2010-03-27 01:54:34.767845	2006-12-13 10:49:54	receiving	\N	\N	1
48	sales	1.000	t	2	2010-03-27 01:54:34.819846	2006-12-30 08:40:54	sales	\N	\N	10
35	computers for kids	1.000	t	2	2010-03-27 01:54:34.831847	2006-12-30 08:40:54	computers_for_kids	\N	\N	10
53	macintosh	1.000	t	1	2010-03-27 01:54:34.867847	2007-01-05 16:10:33	macintosh	\N	\N	2
51	system administration	1.000	t	2	2010-03-27 01:54:34.879847	2006-12-30 08:40:54	system_administration	\N	\N	10
33	admin	1.000	t	2	2010-03-27 01:54:34.895848	2006-12-30 08:40:54	admin	\N	\N	10
46	programming	1.000	t	2	2010-03-27 01:54:34.923848	2006-12-30 08:40:54	programming	\N	\N	10
45	printers	1.000	t	2	2010-03-27 01:54:34.939848	2006-12-30 08:40:54	printers	\N	\N	10
36	CREAM	1.000	t	2	2010-03-27 01:54:34.955849	2006-12-30 08:40:54	cream	\N	\N	10
37	data entry	1.000	t	2	2010-03-27 01:54:34.967849	2006-12-30 08:40:54	data_entry	\N	\N	1
50	support	1.000	t	2	2010-03-27 01:54:34.983849	2006-12-30 08:40:54	support	\N	\N	10
52	testing	1.000	t	2	2010-03-27 01:54:34.995849	2006-12-30 08:40:54	testing	\N	\N	1
41	laptops	1.000	t	3	2010-03-27 01:54:35.011849	2006-12-30 08:40:54	laptops	\N	\N	2
34	advanced testing	1.000	t	3	2010-03-27 01:54:35.02385	2006-12-30 08:40:54	advanced_testing	\N	\N	2
44	outreach	1.000	t	2	2010-03-27 01:54:35.03985	2006-12-30 08:40:54	outreach	\N	\N	10
43	orientation	1.000	t	2	2010-03-27 01:54:35.05185	2006-12-30 08:40:54	orientation	\N	\N	10
40	front desk	1.000	t	2	2010-03-27 01:54:35.06785	2006-12-30 08:40:54	front_desk	\N	\N	10
29	recycling	1.000	t	1	2010-03-27 01:54:35.079851	2006-12-13 10:50:04	recycling	\N	\N	1
25	evaluation	1.000	t	1	2010-03-27 01:54:35.099851	2006-12-13 10:48:21	evaluation	\N	\N	2
21	quality control	1.000	t	3	2010-03-27 01:54:35.111851	2006-12-13 10:46:44	quality_control	\N	\N	2
26	build, assembly	1.000	t	1	2010-03-27 01:54:35.127851	2006-12-13 10:48:52	assembly	\N	\N	2
38	education	1.000	t	2	2010-03-27 01:54:35.143852	2006-12-30 08:40:54	education	\N	\N	10
54	case management	1.000	t	1	2010-03-27 01:54:35.155852	2008-12-12 17:17:50.467874	case management	\N	\N	2
23	cleaning	2.000	t	3	2010-03-27 01:54:35.171852	2006-12-13 10:47:07	cleaning	\N	2009-10-02 00:00:00	1
55	cleaning	1.000	t	3	2010-03-27 01:54:35.183852	2006-12-13 10:47:07	cleaning	2009-10-02 00:00:00	\N	1
22	monitors	2.000	t	3	2010-03-27 01:54:35.199853	2006-12-13 10:46:55	monitors	\N	2009-10-02 00:00:00	1
59	Hardware Grants	1.000	t	1	2010-03-27 01:54:35.255853	2010-02-19 23:43:55.222729	hardware_grants	2009-10-02 22:40:21.818428	\N	10
49	hardware id	1.000	t	1	2010-03-27 01:54:35.271854	2006-12-30 08:40:54.441757	sorting	\N	\N	2
39	server	1.000	t	4	2010-06-26 01:06:56.392275	2006-12-30 08:40:54	server	\N	\N	2
\.


ALTER TABLE volunteer_task_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

