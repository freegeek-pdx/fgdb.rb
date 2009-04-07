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
-- Name: contact_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('contact_types_id_seq', 29, true);


--
-- Data for Name: contact_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE contact_types DISABLE TRIGGER ALL;

COPY contact_types (id, description, for_who, lock_version, updated_at, created_at, instantiable, name) FROM stdin;
28	dropout	per	0	2008-07-19 16:17:50.566943	2008-07-19 16:17:50.566943	t	dropout
15	certified	per	0	2006-12-29 17:07:36.516211	2006-12-29 17:07:36.516211	t	certified
12	adopter	per	0	2006-12-29 17:07:36.465725	2006-12-29 17:07:36.465725	t	adopter
24	recycler	any	0	2006-12-29 17:07:36.567347	2006-12-29 17:07:36.567347	t	recycler
19	grantor	any	0	2006-12-29 17:07:36.526178	2006-12-29 17:07:36.526178	t	grantor
25	waiting	per	0	2006-12-29 17:07:36.575575	2006-12-29 17:07:36.575575	t	waiting
23	preferemail	any	0	2006-12-29 17:07:36.559139	2006-12-29 17:07:36.559139	t	preferemail
14	buyer	any	0	2006-12-29 17:07:36.513717	2006-12-29 17:07:36.513717	t	buyer
4	volunteer	per	1	2006-11-25 00:48:56	2006-09-20 07:44:25	t	volunteer
26	offsite	per	0	2008-06-04 16:19:03.40664	2008-06-04 16:19:03.40664	t	offsite
21	member	any	0	2006-12-29 17:07:36.542696	2006-12-29 17:07:36.542696	t	member
3	staff	per	1	2006-11-25 00:49:27	2006-09-20 07:44:20	t	staff
13	build	per	0	2006-12-29 17:07:36.511086	2006-12-29 17:07:36.511086	t	build
27	bulk buyer	any	0	2008-06-27 22:34:21.493845	2008-06-27 22:34:21.493845	t	bulk_buyer
16	comp4kids	any	0	2006-12-29 17:07:36.518681	2006-12-29 17:07:36.518681	t	comp4kids
5	nonprofit	org	2	2006-11-25 00:49:18	2006-09-20 07:44:41	t	nonprofit
7	donor	any	0	2006-09-20 07:45:14	2006-09-20 07:45:14	t	donor
29	no mail	any	0	2008-12-05 19:01:57.61521	2008-12-05 19:01:57.61521	t	nomail
\.


ALTER TABLE contact_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

