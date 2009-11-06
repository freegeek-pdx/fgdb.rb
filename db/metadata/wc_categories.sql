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
-- Name: wc_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('wc_categories_id_seq', 8, true);


--
-- Data for Name: wc_categories; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE wc_categories DISABLE TRIGGER ALL;

COPY wc_categories (id, name, description, rate_cents, created_at, updated_at) FROM stdin;
4	3574 02	Computing/Office Machine Mfg-Noc	133	2009-10-31 13:25:38.100891	2009-10-31 13:25:38.100891
5	7380 07	Drivers/Chauffrs/Messengers & Helpr	512	2009-10-31 13:25:38.10489	2009-10-31 13:25:38.10489
6	8264 10	Recycling Operation	531	2009-10-31 13:25:38.10489	2009-10-31 13:25:38.10489
7	8810 03	Office Clerical	91	2009-10-31 13:25:38.10889	2009-10-31 13:25:38.10889
8	5191 01	Computer Dev-Instl/Inspec/Ser/Repr	84	2009-10-31 13:25:38.10889	2009-10-31 13:25:38.10889
\.


ALTER TABLE wc_categories ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

