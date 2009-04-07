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

SELECT pg_catalog.setval('gizmo_types_id_seq', 64, true);


--
-- Data for Name: gizmo_types; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE gizmo_types DISABLE TRIGGER ALL;

COPY gizmo_types (id, description, parent_id, lock_version, updated_at, created_at, required_fee_cents, suggested_fee_cents, gizmo_category_id, name, covered, rank) FROM stdin;
37	Cable	13	1	2008-05-30 22:30:58.602659	2007-01-10 15:48:42	0	0	4	cable	f	0
20	zzz Old Data Schwag	17	1	2008-05-30 22:30:58.539574	2006-12-30 15:02:32	0	0	4	old_data_schwag	f	0
33	zzz Video Card	30	3	2008-05-30 22:30:58.588091	2007-01-02 11:50:20	0	0	4	video_card	f	0
19	zzz Old Data Gizmo	13	1	2008-05-30 22:30:58.534699	2006-12-30 15:01:16	0	0	4	old_data_gizmo	f	0
34	zzz Sound Card	30	2	2008-05-30 22:30:58.592979	2007-01-02 11:50:48	0	0	4	sound_card	f	0
28	zzz Modem	13	3	2008-05-30 22:30:58.675204	2007-01-02 10:06:36	0	200	4	modem	f	0
21	zzz Old Data CRT	13	1	2008-05-30 22:30:58.47611	2006-12-30 18:57:55	1000	0	2	old_data_crt	t	0
3	zzz Old Fee CRT	13	4	2008-05-30 22:30:58.471207	2006-09-25 11:22:11	1000	0	2	old_crt	t	0
5	zzz Old Fee Sys w/ monitor	13	5	2008-05-30 22:30:58.504698	2006-09-29 14:22:28	1000	0	1	old_sys_with_monitor	t	0
25	zzz Stereo System	13	2	2008-05-30 22:30:58.568755	2007-01-02 10:04:58	0	400	4	stereo_system	f	0
16	zzz T-Shirt	17	2	2008-05-30 22:30:58.529744	2006-11-11 19:19:26	0	0	4	t-shirt	f	0
15	zzz Sticker	17	2	2008-05-30 22:30:58.524829	2006-11-11 19:19:08	0	0	4	sticker	f	0
32	Optical Drive	43	3	2008-05-30 22:30:58.650888	2007-01-02 11:36:02	0	100	4	cd_burner	f	99
40	As Is Laptop	13	2	2008-05-30 22:30:58.6221	2007-04-24 17:33:43	0	0	4	laptop_parts	f	0
58	A/V	13	0	2008-12-31 15:01:08.126203	2008-12-31 15:01:08.126203	0	300	4	av_gizmo	f	99
39	Mac System	4	1	2008-05-30 22:30:58.612372	2007-04-19 17:26:22	0	0	1	mac	t	0
57	PDA/Cell Phone/MP3	13	0	2008-12-31 15:01:08.122445	2008-12-31 15:01:08.122445	0	100	4	pda_cell_phone	f	99
17	T-Shirt/Sticker	\N	5	2008-05-30 22:30:58.685012	2006-11-11 19:39:41	0	0	4	schwag	f	0
13	Gizmo	\N	5	2008-05-30 22:30:58.689829	2006-11-11 19:16:03	0	0	4	gizmo	f	0
48	Fee Discount	\N	0	2008-07-25 21:48:34.757712	2008-07-25 21:48:34.757712	0	0	4	fee_discount	f	0
52	Mac Part	13	0	\N	\N	0	0	4	mac_part	f	0
35	Case	13	1	2008-05-30 22:30:58.597832	2007-01-10 15:47:37	0	0	4	case	f	0
45	Gift Cert	\N	1	2008-05-30 22:30:58.694651	2007-12-11 17:01:35	0	0	4	gift_cert	f	0
0	[root]	\N	1	2008-05-30 22:30:58.680052	2008-03-27 10:41:53.50475	0	0	4	root	f	0
56	Camera	13	0	2008-12-31 15:01:08.04977	2008-12-31 15:01:08.04977	0	200	4	camera	f	99
43	Drive (other)	13	2	2008-05-30 22:30:58.636599	2007-08-22 14:03:55	0	100	4	drive_other	f	99
26	Phone	13	2	2008-05-30 22:30:58.573576	2007-01-02 10:05:31	0	200	4	phone	f	99
31	Bag/Box Misc	13	3	2008-05-30 22:30:58.631744	2007-01-02 10:09:22	0	100	4	bag_box_misc	f	99
41	RAM	13	1	2008-05-30 22:30:58.617271	2007-04-24 17:34:10	0	200	4	ram	f	99
36	Network Device	13	2	2008-05-30 22:30:58.660627	2007-01-10 15:48:05	0	100	4	net_device	f	99
6	Laptop	4	2	2008-05-30 22:30:58.509601	2006-11-11 19:05:26	0	400	1	laptop	t	7
4	System	13	7	2008-05-30 22:30:58.499747	2006-09-25 11:22:30	0	500	1	system	t	8
30	Card	13	2	2008-05-30 22:30:58.583279	2007-01-02 10:08:06	0	100	4	card	f	99
22	Keyboard	13	2	2008-05-30 22:30:58.559	2007-01-02 10:03:00	0	100	4	keyboard	f	99
10	Printer	13	2	2008-05-30 22:30:58.45908	2006-11-11 19:09:26	0	400	3	printer	f	99
12	Fax Machine	13	2	2008-05-30 22:30:58.443885	2006-11-11 19:13:34	0	400	3	fax_machine	f	99
23	Mouse	13	2	2008-05-30 22:30:58.563893	2007-01-02 10:03:31	0	100	4	mouse	f	99
44	TV-CRT	13	1	2008-05-30 22:30:58.665457	2007-10-23 19:17:36	1000	0	2	tv_crt	t	1
49	Monitor-CRT	13	0	2008-10-10 22:42:44.86573	2008-10-10 22:42:44.86573	700	0	2	monitor_crt	t	2
50	System w/ CRT	13	0	2008-10-10 22:42:45.058719	2008-10-10 22:42:45.058719	700	0	1	system_crt	t	3
46	Service Fee	\N	1	2008-05-30 22:30:58.699506	2007-12-11 17:41:55	100	0	4	service_fee	f	99
27	Hard Drive	43	5	2008-05-30 22:30:58.655773	2007-01-02 10:06:08	0	100	4	hard_drive	f	99
29	Speaker Set	13	2	2008-05-30 22:30:58.578448	2007-01-02 10:07:34	0	100	4	speaker_set	f	99
59	Multi-function Printer	13	0	2008-12-31 15:27:35.128929	2008-12-31 15:27:35.128929	0	100	3	mult_printer	f	99
60	Miscellaneous Item	13	0	2008-12-31 15:27:35.20746	2008-12-31 15:27:35.20746	0	100	4	misc_item	f	99
42	Power supply	13	1	2008-05-30 22:30:58.626915	2007-04-24 17:36:24	0	100	4	power_supply	f	99
63	PC Part	13	0	2009-01-10 13:49:44.654128	2009-01-10 13:49:44.654128	0	100	4	pc_part	f	0
7	zzz VCR	13	3	2008-05-30 22:30:58.549293	2006-11-11 19:08:37	0	300	4	vcr	f	0
11	Scanner	13	2	2008-05-30 22:30:58.454222	2006-11-11 19:09:38	0	300	3	scanner	f	99
14	UPS	13	2	2008-05-30 22:30:58.544425	2006-11-11 19:18:08	0	500	4	ups	f	99
8	zzz DVD Player	13	3	2008-05-30 22:30:58.554147	2006-11-11 19:08:52	0	300	4	dvd_player	f	0
61	Laptop Bag	13	0	2009-01-10 13:49:44.64376	2009-01-10 13:49:44.64376	0	100	4	laptop_bag	f	99
62	Motherboard	13	0	2009-01-10 13:49:44.652469	2009-01-10 13:49:44.652469	0	100	4	motherboard	f	99
55	TV-LCD	13	0	2008-12-30 13:39:46.377134	2008-12-30 13:39:46.377134	0	500	2	tv_lcd	t	4
54	System w/ LCD	13	0	2008-12-30 13:39:46.30323	2008-12-30 13:39:46.30323	0	500	1	system_lcd	t	6
2	Monitor-LCD	13	4	2008-05-30 22:30:58.492476	2006-09-25 11:21:53	0	400	2	monitor_lcd	t	5
\.


ALTER TABLE gizmo_types ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

