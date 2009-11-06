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
-- Name: defaults_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('defaults_id_seq', 19, true);


--
-- Data for Name: defaults; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE defaults DISABLE TRIGGER ALL;

COPY defaults (id, name, value, lock_version, updated_at, created_at) FROM stdin;
3	tax id	Federal Tax I.D.  93-1292010	0	2007-04-16 14:16:07	2007-04-16 14:16:07
6	country	United States	0	2007-04-16 14:16:42	2007-04-16 14:16:42
4	address image	/images/hdr-address.gif	0	2007-04-16 14:16:41	2007-04-16 14:16:41
5	business id		0	2007-04-16 14:22:06	2007-04-16 14:22:06
7	contact info	addr: 1731 SE 10th Portland, OR 97214 tele: 503.232.9350 email: info@freegeek.org	0	2007-04-16 14:22:16	2007-04-16 14:22:16
2	state_or_province	OR	1	2007-04-16 14:33:55	2007-04-16 14:15:25
1	city	Portland	1	2007-04-16 14:34:29	2007-04-16 14:15:10
8	my_email_address	fgdb@freegeek.org	0	\N	\N
9	volunteer_reports_to	inreach@todo.freegeek.org	0	\N	\N
13	fully_covered_contact_covered_gizmo	-1	0	2008-12-22 09:00:53.770448	2008-12-22 09:00:53.770448
14	unfully_covered_contact_covered_gizmo	7	0	2008-12-22 09:00:53.78511	2008-12-22 09:00:53.78511
16	max_effective_hours	24.0	1	2009-05-15 23:53:59.595633	2009-05-02 17:10:41.606476
18	hours_for_discount	3.0	0	2009-10-02 22:40:22.47043	2009-10-02 22:40:22.47043
19	days_for_discount	31	0	2009-10-02 22:40:22.49443	2009-10-02 22:40:22.49443
12	coveredness_enabled	0	1	2009-11-03 17:28:19.922686	2008-12-22 09:00:53.614147
15	is-pdx	false	1	2009-11-04 16:16:30.056703	2008-12-22 09:01:02.01784
\.


ALTER TABLE defaults ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

