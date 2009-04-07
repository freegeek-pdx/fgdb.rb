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

SELECT pg_catalog.setval('volunteer_task_types_id_seq', 54, true);


--
-- Data for Name: volunteer_task_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE volunteer_task_types DISABLE TRIGGER ALL;

COPY volunteer_task_types (id, description, parent_id, hours_multiplier, instantiable, lock_version, updated_at, created_at, name) FROM stdin;
32	slacking	17	0.000	t	0	2006-12-13 21:14:14	2006-12-13 21:14:14	slacking
31	massage	17	4.000	t	0	2006-12-13 11:04:35	2006-12-13 11:04:35	massage
42	misc	17	1.000	t	1	2006-12-30 18:22:55	2006-12-30 08:40:54	misc
0	[root]	\N	1.000	f	1	2008-04-01 08:12:20.130494	2008-03-27 10:54:21.545744	root
47	repair	24	1.000	t	0	2006-12-30 08:40:54.425307	2006-12-30 08:40:54.425307	repair
30	teaching	17	1.000	t	0	2006-12-13 11:04:23	2006-12-13 11:04:23	teaching
28	receiving	27	1.000	t	0	2006-12-13 10:49:54	2006-12-13 10:49:54	receiving
27	adoption	17	1.000	f	0	2006-12-13 10:49:16	2006-12-13 10:49:16	adoption
39	enterprise	24	1.000	t	2	2006-12-30 18:27:40	2006-12-30 08:40:54	enterprise
48	sales	17	1.000	t	1	2006-12-30 18:23:02	2006-12-30 08:40:54	sales
35	computers for kids	17	1.000	t	1	2006-12-30 18:22:08	2006-12-30 08:40:54	computers_for_kids
23	cleaning	27	2.000	t	1	2006-12-13 10:49:27	2006-12-13 10:47:07	cleaning
53	macintosh	24	1.000	t	0	2007-01-05 16:10:33	2007-01-05 16:10:33	macintosh
51	system administration	17	1.000	t	1	2006-12-30 18:23:04	2006-12-30 08:40:54	system_administration
33	admin	17	1.000	t	1	2006-12-30 18:21:20	2006-12-30 08:40:54	admin
24	build	17	1.000	f	0	2006-12-13 10:47:39	2006-12-13 10:47:39	build
46	programming	17	1.000	t	1	2006-12-30 18:23:00	2006-12-30 08:40:54	programming
45	printers	17	1.000	t	1	2006-12-30 18:22:59	2006-12-30 08:40:54	printers
36	CREAM	17	1.000	t	1	2006-12-30 18:22:10	2006-12-30 08:40:54	cream
37	data entry	27	1.000	t	1	2006-12-30 18:27:34	2006-12-30 08:40:54	data_entry
50	support	17	1.000	t	1	2006-12-30 18:23:03	2006-12-30 08:40:54	support
49	sorting	24	1.000	t	0	2006-12-30 08:40:54.441757	2006-12-30 08:40:54.441757	sorting
52	testing	27	1.000	t	1	2006-12-30 18:28:28	2006-12-30 08:40:54	testing
41	laptops	24	1.000	t	2	2006-12-30 18:27:45	2006-12-30 08:40:54	laptops
34	advanced testing	24	1.000	t	2	2006-12-30 18:27:25	2006-12-30 08:40:54	advanced_testing
44	outreach	17	1.000	t	1	2006-12-30 18:22:58	2006-12-30 08:40:54	outreach
43	orientation	17	1.000	t	1	2006-12-30 18:22:56	2006-12-30 08:40:54	orientation
40	front desk	17	1.000	t	1	2006-12-30 18:22:14	2006-12-30 08:40:54	front_desk
29	recycling	27	1.000	t	0	2006-12-13 10:50:04	2006-12-13 10:50:04	recycling
22	monitors	27	2.000	t	1	2006-12-13 10:49:34	2006-12-13 10:46:55	monitors
17	program	0	1.000	f	1	2008-04-01 08:12:20.134439	2006-12-13 10:45:23	program
25	evaluation	24	1.000	t	0	2006-12-13 10:48:21	2006-12-13 10:48:21	evaluation
21	quality control	24	1.000	t	2	2006-12-13 11:00:21	2006-12-13 10:46:44	quality_control
26	build, assembly	24	1.000	t	0	2006-12-13 10:48:52	2006-12-13 10:48:52	assembly
38	education	17	1.000	t	1	2006-12-30 18:22:11	2006-12-30 08:40:54	education
54	case management	24	1.000	t	0	2008-12-12 17:17:50.467874	2008-12-12 17:17:50.467874	case management
\.


ALTER TABLE volunteer_task_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

