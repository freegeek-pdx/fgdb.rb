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
-- Name: gizmo_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gizmo_types_id_seq', 48, true);


--
-- Data for Name: gizmo_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_types DISABLE TRIGGER ALL;

COPY gizmo_types (id, description, parent_id, lock_version, updated_at, created_at, required_fee_cents, suggested_fee_cents, gizmo_category_id, name) FROM stdin;
21	Old Data CRT	1	1	2008-06-07 15:10:26.487829	2006-12-30 18:57:55	1000	0	2	old_data_crt
10	Printer	13	2	2008-06-07 15:10:26.473995	2006-11-11 19:09:26	0	400	3	printer
12	Fax Machine	13	2	2008-06-07 15:10:26.466035	2006-11-11 19:13:34	0	400	3	fax_machine
45	Gift Cert	\N	1	2008-06-07 15:10:26.640689	2007-12-11 17:01:35	0	0	4	gift_cert
44	Television	1	1	2008-06-07 15:10:26.617673	2007-10-23 19:17:36	1000	0	4	television
27	Harddrive	43	5	2008-06-07 15:10:26.609894	2007-01-02 10:06:08	0	100	4	harddrive
29	Speakers	13	2	2008-06-07 15:10:26.557868	2007-01-02 10:07:34	0	100	4	speakers
42	Power supply	13	1	2008-06-07 15:10:26.595332	2007-04-24 17:36:24	0	0	4	power_supply
34	Sound Card	30	2	2008-06-07 15:10:26.569101	2007-01-02 11:50:48	0	0	4	sound_card
11	Scanner	13	2	2008-06-07 15:10:26.470505	2006-11-11 19:09:38	0	300	3	scanner
0	[root]	\N	1	2008-06-07 15:10:26.629222	2008-03-27 10:41:53.50475	0	0	4	root
14	UPS	13	2	2008-06-07 15:10:26.530353	2006-11-11 19:18:08	0	500	4	ups
20	Old Data Schwag	17	1	2008-06-07 15:10:26.52645	2006-12-30 15:02:32	0	0	4	old_data_schwag
2	LCD	1	4	2008-06-07 15:10:26.491642	2006-09-25 11:21:53	0	400	2	lcd
28	Modem	13	3	2008-06-07 15:10:26.62565	2007-01-02 10:06:36	0	200	4	modem
43	Drive	13	2	2008-06-07 15:10:26.602495	2007-08-22 14:03:55	0	100	4	drive
31	Miscellaneous	13	3	2008-06-07 15:10:26.599119	2007-01-02 10:09:22	0	100	4	miscellaneous
33	Video Card	30	3	2008-06-07 15:10:26.565328	2007-01-02 11:50:20	0	0	4	video_card
18	1337 lappy	6	3	2008-06-07 15:10:26.507919	2006-12-19 20:16:28	0	0	1	1337_lappy
13	Gizmo	\N	5	2008-06-07 15:10:26.636821	2006-11-11 19:16:03	0	0	4	gizmo
39	Mac	4	1	2008-06-07 15:10:26.583557	2007-04-19 17:26:22	0	0	4	mac
36	Net Device	13	2	2008-06-07 15:10:26.613686	2007-01-10 15:48:05	0	100	4	net_device
48	Fee Discount	\N	0	2008-07-31 16:41:25.224914	2008-07-31 16:41:25.224914	0	0	4	fee_discount
47	Old Data System	19	1	2008-06-07 15:10:26.621635	2008-03-11 18:26:39	0	500	4	old_data_system
32	CD Burner	43	3	2008-06-07 15:10:26.606089	2007-01-02 11:36:02	0	0	4	cd_burner
25	Stereo System	13	2	2008-06-07 15:10:26.549669	2007-01-02 10:04:58	0	400	4	stereo_system
7	VCR	13	3	2008-06-07 15:10:26.533854	2006-11-11 19:08:37	0	300	4	vcr
3	CRT	1	4	2008-06-07 15:10:26.483946	2006-09-25 11:22:11	1000	0	2	crt
40	Laptop parts	13	2	2008-06-07 15:10:26.591542	2007-04-24 17:33:43	0	0	4	laptop_parts
26	Telephone	13	2	2008-06-07 15:10:26.554098	2007-01-02 10:05:31	0	200	4	telephone
8	DVD Player	13	3	2008-06-07 15:10:26.53762	2006-11-11 19:08:52	0	300	4	dvd_player
4	System	13	7	2008-06-07 15:10:26.496861	2006-09-25 11:22:30	0	500	1	system
1	Monitor	13	8	2008-06-07 15:10:26.479961	2006-09-25 11:21:29	0	0	2	monitor
5	Sys w/ monitor	1	5	2008-06-07 15:10:26.500512	2006-09-29 14:22:28	1000	0	1	sys_with_monitor
46	Service Fee	\N	1	2008-06-07 15:10:26.644611	2007-12-11 17:41:55	100	0	4	service_fee
17	Schwag	\N	5	2008-06-07 15:10:26.632957	2006-11-11 19:39:41	0	0	4	schwag
35	Case	13	1	2008-06-07 15:10:26.572486	2007-01-10 15:47:37	0	0	4	case
30	Card	13	2	2008-06-07 15:10:26.561549	2007-01-02 10:08:06	0	100	4	card
22	Keyboard	13	2	2008-06-07 15:10:26.541351	2007-01-02 10:03:00	0	100	4	keyboard
41	RAM	13	1	2008-06-07 15:10:26.58756	2007-04-24 17:34:10	0	0	4	ram
38	Tuition	17	1	2008-06-07 15:10:26.579804	2007-01-17 14:35:51	0	0	4	tuition
6	Laptop	4	2	2008-06-07 15:10:26.504157	2006-11-11 19:05:26	0	400	1	laptop
37	Cable	13	1	2008-06-07 15:10:26.576212	2007-01-10 15:48:42	0	0	4	cable
23	Mouse	13	2	2008-06-07 15:10:26.545624	2007-01-02 10:03:31	0	100	4	mouse
19	Old Data Gizmo	13	1	2008-06-07 15:10:26.522508	2006-12-30 15:01:16	0	0	4	old_data_gizmo
16	T-Shirt	17	2	2008-06-07 15:10:26.518624	2006-11-11 19:19:26	0	0	4	t-shirt
15	Sticker	17	2	2008-06-07 15:10:26.514841	2006-11-11 19:19:08	0	0	4	sticker
\.


ALTER TABLE gizmo_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

