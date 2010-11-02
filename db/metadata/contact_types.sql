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
-- Name: contact_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('contact_types_id_seq', 30, true);


--
-- Data for Name: contact_types; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE contact_types DISABLE TRIGGER ALL;

COPY contact_types (id, description, for_who, lock_version, updated_at, created_at, instantiable, name) FROM stdin;
15	certified	per	0	2006-12-29 17:07:36.516211	2006-12-29 17:07:36.516211	t	certified
12	adopter	per	0	2006-12-29 17:07:36.465725	2006-12-29 17:07:36.465725	t	adopter
25	waiting	per	0	2006-12-29 17:07:36.575575	2006-12-29 17:07:36.575575	t	waiting
23	preferemail	any	0	2006-12-29 17:07:36.559139	2006-12-29 17:07:36.559139	t	preferemail
26	offsite	per	0	2008-06-04 16:19:03.40664	2008-06-04 16:19:03.40664	t	offsite
21	member	any	0	2006-12-29 17:07:36.542696	2006-12-29 17:07:36.542696	t	member
27	bulk buyer	any	0	2008-06-27 22:34:21.493845	2008-06-27 22:34:21.493845	t	bulk_buyer
5	nonprofit	org	2	2006-11-25 00:49:18	2006-09-20 07:44:41	t	nonprofit
29	no mail	any	0	2008-12-05 19:01:57.61521	2008-12-05 19:01:57.61521	t	nomail
30	contributor	per	0	2009-04-10 00:48:31.391473	2009-04-10 00:48:31.391473	t	contributor
4	volunteer	per	2	2006-11-25 00:48:56	2006-09-20 07:44:25	t	volunteer
16	comp4kids	any	2	2006-12-29 17:07:36.518681	2006-12-29 17:07:36.518681	t	comp4kids
19	grantor	any	1	2006-12-29 17:07:36.526178	2006-12-29 17:07:36.526178	t	grantor
24	recycler	any	1	2006-12-29 17:07:36.567347	2006-12-29 17:07:36.567347	t	recycler
14	buyer	any	12	2006-12-29 17:07:36.513717	2006-12-29 17:07:36.513717	t	buyer
7	donor	any	2	2006-09-20 07:45:14	2006-09-20 07:45:14	t	donor
13	build	per	1	2006-12-29 17:07:36.511086	2006-12-29 17:07:36.511086	t	build
\.


ALTER TABLE contact_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

