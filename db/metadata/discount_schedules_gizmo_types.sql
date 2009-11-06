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
-- Name: discount_schedules_gizmo_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('discount_schedules_gizmo_types_id_seq', 289, true);


--
-- Data for Name: discount_schedules_gizmo_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE discount_schedules_gizmo_types DISABLE TRIGGER ALL;

COPY discount_schedules_gizmo_types (id, gizmo_type_id, discount_schedule_id, multiplier, lock_version, updated_at, created_at) FROM stdin;
38	19	8	1.000	0	2006-12-30 15:01:16	2006-12-30 15:01:16
39	19	9	1.000	0	2006-12-30 15:01:16	2006-12-30 15:01:16
40	19	4	0.500	0	2006-12-30 15:01:16	2006-12-30 15:01:16
41	19	5	1.000	0	2006-12-30 15:01:16	2006-12-30 15:01:16
42	20	8	1.000	0	2006-12-30 15:02:32	2006-12-30 15:02:32
43	20	9	1.000	0	2006-12-30 15:02:32	2006-12-30 15:02:32
44	20	4	0.900	0	2006-12-30 15:02:32	2006-12-30 15:02:32
45	20	5	1.000	0	2006-12-30 15:02:32	2006-12-30 15:02:32
134	17	8	1.000	0	2007-01-02 15:35:38	2007-01-02 15:35:38
135	17	9	1.000	0	2007-01-02 15:35:38	2007-01-02 15:35:38
136	17	4	0.900	0	2007-01-02 15:35:38	2007-01-02 15:35:38
137	17	5	0.950	0	2007-01-02 15:35:38	2007-01-02 15:35:38
186	13	8	1.000	0	2007-01-04 19:06:35	2007-01-04 19:06:35
187	13	9	1.000	0	2007-01-04 19:06:35	2007-01-04 19:06:35
188	13	4	0.500	0	2007-01-04 19:06:35	2007-01-04 19:06:35
189	13	5	0.750	0	2007-01-04 19:06:35	2007-01-04 19:06:35
262	45	8	1.000	0	2007-12-11 17:01:35	2007-12-11 17:01:35
263	45	9	1.000	0	2007-12-11 17:01:35	2007-12-11 17:01:35
264	45	4	1.000	0	2007-12-11 17:01:35	2007-12-11 17:01:35
265	45	5	1.000	0	2007-12-11 17:01:35	2007-12-11 17:01:35
286	73	4	0.800	0	2009-10-09 12:28:01.970223	2009-10-09 12:28:01.970223
287	73	5	0.800	0	2009-10-09 12:28:01.970223	2009-10-09 12:28:01.970223
288	73	8	1.000	0	2009-10-09 12:28:01.970223	2009-10-09 12:28:01.970223
289	73	9	1.000	0	2009-10-09 12:28:01.970223	2009-10-09 12:28:01.970223
\.


ALTER TABLE discount_schedules_gizmo_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

