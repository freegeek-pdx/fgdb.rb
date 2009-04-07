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
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('roles_id_seq', 10, true);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE roles DISABLE TRIGGER ALL;

COPY roles (id, name, created_at, updated_at) FROM stdin;
1	ADMIN	\N	\N
2	FRONT_DESK	\N	\N
3	VOLUNTEER_MANAGER	\N	\N
4	STORE	\N	\N
5	CONTACT_MANAGER	\N	\N
6	BEAN_COUNTER	2008-04-15 09:57:59.126816	\N
7	DONATION_ADMIN	2008-04-15 09:59:30.598238	\N
8	STORE_ADMIN	2008-04-15 09:59:35.107392	\N
9	RECYCLINGS	2008-12-22 09:00:53.862156	2008-12-22 09:00:53.862156
10	SKEDJULNATOR	2009-02-06 23:48:33.442751	2009-02-06 23:48:33.442751
\.


ALTER TABLE roles ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

