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
-- Name: volunteer_task_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('volunteer_task_types_id_seq', 53, true);


--
-- Data for Name: volunteer_task_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE volunteer_task_types DISABLE TRIGGER ALL;

COPY volunteer_task_types (id, description, parent_id, hours_multiplier, instantiable, lock_version, updated_at, created_at) FROM stdin;
27	adoption	17	1.000	f	0	2006-12-13 10:49:16	2006-12-13 10:49:16
23	cleaning	27	2.000	t	1	2006-12-13 10:49:27	2006-12-13 10:47:07
22	monitors	27	2.000	t	1	2006-12-13 10:49:34	2006-12-13 10:46:55
28	receiving	27	1.000	t	0	2006-12-13 10:49:54	2006-12-13 10:49:54
29	recycling	27	1.000	t	0	2006-12-13 10:50:04	2006-12-13 10:50:04
21	quality control	24	1.000	t	2	2006-12-13 11:00:21	2006-12-13 10:46:44
30	teaching	17	1.000	t	0	2006-12-13 11:04:23	2006-12-13 11:04:23
31	massage	17	4.000	t	0	2006-12-13 11:04:35	2006-12-13 11:04:35
32	slacking	17	0.000	t	0	2006-12-13 21:14:14	2006-12-13 21:14:14
47	repair	24	1.000	t	0	2006-12-30 08:40:54.425307	2006-12-30 08:40:54.425307
49	sorting	24	1.000	t	0	2006-12-30 08:40:54.441757	2006-12-30 08:40:54.441757
33	admin	17	1.000	t	1	2006-12-30 18:21:20	2006-12-30 08:40:54
35	computers for kids	17	1.000	t	1	2006-12-30 18:22:08	2006-12-30 08:40:54
36	CREAM	17	1.000	t	1	2006-12-30 18:22:10	2006-12-30 08:40:54
38	education	17	1.000	t	1	2006-12-30 18:22:11	2006-12-30 08:40:54
40	front desk	17	1.000	t	1	2006-12-30 18:22:14	2006-12-30 08:40:54
42	misc	17	1.000	t	1	2006-12-30 18:22:55	2006-12-30 08:40:54
43	orientation	17	1.000	t	1	2006-12-30 18:22:56	2006-12-30 08:40:54
44	outreach	17	1.000	t	1	2006-12-30 18:22:58	2006-12-30 08:40:54
45	printers	17	1.000	t	1	2006-12-30 18:22:59	2006-12-30 08:40:54
46	programming	17	1.000	t	1	2006-12-30 18:23:00	2006-12-30 08:40:54
48	sales	17	1.000	t	1	2006-12-30 18:23:02	2006-12-30 08:40:54
50	support	17	1.000	t	1	2006-12-30 18:23:03	2006-12-30 08:40:54
51	system administration	17	1.000	t	1	2006-12-30 18:23:04	2006-12-30 08:40:54
34	advanced testing	24	1.000	t	2	2006-12-30 18:27:25	2006-12-30 08:40:54
37	data entry	27	1.000	t	1	2006-12-30 18:27:34	2006-12-30 08:40:54
39	enterprise	24	1.000	t	2	2006-12-30 18:27:40	2006-12-30 08:40:54
41	laptops	24	1.000	t	2	2006-12-30 18:27:45	2006-12-30 08:40:54
52	testing	27	1.000	t	1	2006-12-30 18:28:28	2006-12-30 08:40:54
53	macintosh	24	1.000	t	0	2007-01-05 16:10:33	2007-01-05 16:10:33
25	evaluation	24	1.000	t	0	2006-12-13 10:48:21	2006-12-13 10:48:21
24	build	17	1.000	f	0	2006-12-13 10:47:39	2006-12-13 10:47:39
26	build, assembly	24	1.000	t	0	2006-12-13 10:48:52	2006-12-13 10:48:52
0	[root]	\N	1.000	f	1	2008-04-01 08:12:20.130494	2008-03-27 10:54:21.545744
17	program	0	1.000	f	1	2008-04-01 08:12:20.134439	2006-12-13 10:45:23
\.


ALTER TABLE volunteer_task_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

