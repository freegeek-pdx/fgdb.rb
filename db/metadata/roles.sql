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

SELECT pg_catalog.setval('roles_id_seq', 8, true);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE roles DISABLE TRIGGER ALL;

COPY roles (id, name, created_at, updated_at) FROM stdin;
1	ROLE_ADMIN	\N	\N
2	ROLE_FRONT_DESK	\N	\N
3	ROLE_VOLUNTEER_MANAGER	\N	\N
4	ROLE_STORE	\N	\N
5	ROLE_CONTACT_MANAGER	\N	\N
6	ROLE_BEAN_COUNTER	2008-04-15 09:57:59.126816	\N
7	ROLE_DONATION_ADMIN	2008-04-15 09:59:30.598238	\N
8	ROLE_STORE_ADMIN	2008-04-15 09:59:35.107392	\N
\.


ALTER TABLE roles ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

