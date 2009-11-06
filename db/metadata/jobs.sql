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
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('jobs_id_seq', 117, true);


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE jobs DISABLE TRIGGER ALL;

COPY jobs (id, name, description, coverage_type_id, income_stream_id, wc_category_id, program_id) FROM stdin;
0	0 unavailable 0	\N	2	\N	\N	\N
2	Laptops	\N	2	\N	\N	\N
23	CommandLine	\N	2	\N	\N	\N
31	Advanced Linux	\N	2	\N	\N	\N
32	Build	\N	2	\N	\N	\N
56	Close	\N	2	\N	\N	\N
65	Free Computers!	\N	2	\N	\N	\N
70	Offsite Donations	\N	2	\N	\N	\N
77	Advanced Testing	\N	3	\N	\N	\N
100	Tour Guide	Orient prospective volunteers and other interested people to Free Geek.	2	\N	\N	\N
42	Hardware Donations	Coordinate volunteers while receiving gizmos	1	\N	\N	\N
101	Adoption Supplies	Stock the adoption class supplies.	4	\N	\N	\N
102	Meet and Greet	Get volunteers from the front door to their stations and see how they're doing.	2	\N	\N	\N
58	Floater and Stocking		3	\N	\N	\N
41	Office Coordination	Filing, establishing systems, etc.	5	\N	\N	\N
40	Bean Counting		4	\N	\N	\N
76	Bookkeeping		4	\N	\N	\N
14	Coding & Sysadmin		4	\N	\N	\N
71	Education Coordination		5	\N	\N	\N
63	Facilities Maintenance		3	\N	\N	\N
36	Feeding Loki	Going to the bank	4	\N	\N	\N
79	Food Run		3	\N	\N	\N
4	Front Desk		1	\N	\N	\N
78	Mac Build		3	\N	\N	\N
68	Online Sales		4	\N	\N	\N
35	Printers		3	\N	\N	\N
1	Production Coord		3	\N	\N	\N
3	Recycling		1	\N	\N	\N
28	Scheduling		4	\N	\N	\N
13	Supply Check		3	\N	\N	\N
37	Supply Run		3	\N	\N	\N
16	Thrift Store		1	\N	\N	\N
104	Outreach Projects		5	\N	\N	\N
103	Volunteer Program Projects	Volunteer intern coordination, outreach to new volunteer pools, corresponding with volunteers, documentation, etc.	5	\N	\N	\N
6	Teaching	Adoption and advanced adoption teaching.	2	\N	\N	\N
59	Grants	Hardware grant shepherding	5	\N	\N	\N
55	Tech Support Admin	\N	2	\N	\N	\N
66	Inreach Projects		2	\N	\N	\N
69	Reply to eMails		5	\N	\N	\N
74	Group volunteers		5	\N	\N	\N
39	Recycling Coordination		5	\N	\N	\N
17	Tech Support	\N	2	\N	\N	\N
105	Action Tasks		5	\N	\N	\N
106	Laptop Admin		5	\N	\N	\N
107	Institutional Outreach		4	\N	\N	\N
108	Mtg Prep		5	\N	\N	\N
109	Intergalactic		5	\N	\N	\N
5	Prebuild		1	\N	\N	\N
110	Tech walk thru		5	\N	\N	\N
111	Safari	elephant hunting	1	\N	\N	\N
112	Documentation		1	\N	\N	\N
113	Printer Admin	All the stuff you need to do with printers that\r\nyou can't do when on printer shifts	4	\N	\N	\N
114	Server Build		1	\N	\N	\N
115	Production Floater	Covering Build and Laptops, or Laptops and Advanced Testing or whatever at the same time.	1	\N	\N	\N
116	Office Work		4	\N	\N	\N
117	Training	Training	1	\N	\N	\N
\.


ALTER TABLE jobs ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

