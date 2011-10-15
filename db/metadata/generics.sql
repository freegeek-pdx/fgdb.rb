--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: generics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('generics_id_seq', 46, true);


--
-- Data for Name: generics; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE generics DISABLE TRIGGER ALL;

COPY generics (id, value, only_serial, usable, created_at, updated_at) FROM stdin;
1	�����	t	t	2008-11-01 03:36:19.665583	2008-11-01 03:36:19.665583
2	0123456789ABCDEF	t	t	2008-11-01 03:36:19.68929	2008-11-01 03:36:19.68929
3	0123456789	t	t	2008-11-01 03:36:19.708323	2008-11-01 03:36:19.708323
4	1234567890	t	t	2008-11-01 03:36:19.716063	2008-11-01 03:36:19.716063
5	MB-1234567890	t	t	2008-11-01 03:36:19.723821	2008-11-01 03:36:19.723821
6	SYS-1234567890	t	t	2008-11-01 03:36:19.731585	2008-11-01 03:36:19.731585
7	00000000	t	t	2008-11-01 03:36:19.739297	2008-11-01 03:36:19.739297
8	xxxxxxxxxxx	t	t	2008-11-01 03:36:19.747002	2008-11-01 03:36:19.747002
9	EVAL	t	t	2008-11-01 03:36:19.754793	2008-11-01 03:36:19.754793
10	Serial number xxxxxx	t	t	2008-11-01 03:36:19.763041	2008-11-01 03:36:19.763041
11	XXXXXXXXXX	t	t	2008-11-01 03:36:19.770911	2008-11-01 03:36:19.770911
12	$	t	t	2008-11-01 03:36:19.778633	2008-11-01 03:36:19.778633
13	xxxxxxxxxx	t	t	2008-11-01 03:36:19.786362	2008-11-01 03:36:19.786362
14	xxxxxxxxxxxx	t	t	2008-11-01 03:36:19.794299	2008-11-01 03:36:19.794299
15	xxxxxxxxxxxxxx	t	t	2008-11-01 03:36:19.802282	2008-11-01 03:36:19.802282
16	0000000000	t	t	2008-11-01 03:36:19.809997	2008-11-01 03:36:19.809997
17	DELL	t	t	2008-11-01 03:36:19.817731	2008-11-01 03:36:19.817731
18	0	t	t	2008-11-01 03:36:19.825445	2008-11-01 03:36:19.825445
19	123456789000	t	t	2008-11-01 03:36:19.833299	2008-11-01 03:36:19.833299
20	123456890	t	t	2008-11-01 03:36:19.841038	2008-11-01 03:36:19.841038
21	System Name	f	t	2008-11-01 03:36:19.848966	2008-11-01 03:36:19.848966
22	Product Name	f	t	2008-11-01 03:36:19.85732	2008-11-01 03:36:19.85732
23	System Manufacturer	f	t	2008-11-01 03:36:19.865222	2008-11-01 03:36:19.865222
24	none	f	t	2008-11-01 03:36:19.87318	2008-11-01 03:36:19.87318
25	None	f	t	2008-11-01 03:36:19.881132	2008-11-01 03:36:19.881132
26	To Be Filled By O.E.M.	f	t	2008-11-01 03:36:19.888996	2008-11-01 03:36:19.888996
27	To Be Filled By O.E.M. by More String	f	t	2008-11-01 03:36:19.898615	2008-11-01 03:36:19.898615
28	OEM00000	f	t	2008-11-01 03:36:19.906613	2008-11-01 03:36:19.906613
29	PROD00000000	f	t	2008-11-01 03:36:19.9146	2008-11-01 03:36:19.9146
30	0000000000000	t	t	2008-11-08 16:57:39.05906	2008-11-08 16:57:39.05906
31	VH\\	t	t	2008-12-05 19:10:45.166659	2008-12-05 19:10:45.166659
32	V        H 8\\	t	t	2008-12-06 09:27:48.864717	2008-12-06 09:27:48.864717
33	System Serial Number	f	t	2010-02-19 23:43:55.266729	2010-02-19 23:43:55.266729
34	System Product Name	f	t	2010-02-19 23:43:55.306728	2010-02-19 23:43:55.306728
35	System manufacturer	f	t	2010-02-19 23:43:55.410728	2010-02-19 23:43:55.410728
36	stem manufacturer	f	t	2010-02-19 23:43:55.474728	2010-02-19 23:43:55.474728
37	Serial#	t	t	\N	\N
38	.       .              .	t	t	2010-07-19 23:13:21.079775	2010-07-19 23:13:21.079775
39	To be filled by O.E.M.	t	t	2010-07-19 23:13:21.303782	2010-07-19 23:13:21.303782
40	System serial number	t	t	2010-07-19 23:13:21.315783	2010-07-19 23:13:21.315783
41	NA60B7Y0S3Q	t	t	2010-07-19 23:13:21.327783	2010-07-19 23:13:21.327783
42	Chassis Serial Number	f	t	2010-07-19 23:13:21.335783	2010-07-19 23:13:21.335783
43	Chassis Manufacture	f	t	2010-07-19 23:13:21.347784	2010-07-19 23:13:21.347784
44	System product name	f	t	2010-07-19 23:13:21.359784	2010-07-19 23:13:21.359784
45	Ssystem manufacturer	f	t	2010-07-19 23:13:21.371785	2010-07-19 23:13:21.371785
46	INVALID	f	t	\N	\N
\.


ALTER TABLE generics ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

