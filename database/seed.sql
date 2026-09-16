--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

-- Started on 2026-09-12 22:42:13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5032 (class 0 OID 26308)
-- Dependencies: 231
-- Data for Name: configuracion_comercio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracion_comercio (id, razon_social, nit, direccion, telefono, prefijo_factura, resolucion_dian, regimen, actualizado_en, nombre_comercial, logo_url, email, ciudad) FROM stdin;
1	Comercializadora Cuadre S.A.S.	901234567-8	Calle 45 # 12-30	3001234567	F	\N	NO RESPONSABLE DE IVA	2026-09-10 15:01:16.415731-05	Cuadre POS	https://media.istockphoto.com/id/1201144331/es/vector/logotipo-de-icon-design-element-para-la-empresa-de-innovaci%C3%B3n-tecnol%C3%B3gica-icono-tecnol%C3%B3gico.jpg?s=2048x2048&w=is&k=20&c=NTaJ1oDHiv5LcKfQDYERiw_MrDXdkCARng2m8qQXa1c=	contacto@cuadrepos.co	Bogotá D.C.
\.


--
-- TOC entry 5028 (class 0 OID 26259)
-- Dependencies: 227
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id, email, nombre, password_hash, rol, activo, creado_en, ultimo_acceso, comercio_id, foto_url, debe_cambiar_password) FROM stdin;
1	admin@cuadrepos.co	Administrador demo	$2b$12$1.M8rSma4qX1DZsrVjnNoet2A.yT.Z8cKEUZ7wPQSWoR8b/EX/nZu	ADMIN	t	2026-09-10 01:00:58.293923-05	2026-09-13 03:00:57.556093-05	1	\N	f
2	cajero@cuadrepos.co	Cajero demo	$2b$12$sJSDTp95vhDls5pshxIiNunh9JKcP.z4JisDOBF2DwhssEvAuDLlG	CAJERO	t	2026-09-10 01:00:58.293923-05	2026-09-13 03:07:37.833532-05	1	https://as1.ftcdn.net/jpg/08/05/28/22/220_F_805282248_LHUxw7t2pnQ7x8lFEsS2IZgK8IGFXePS.jpg	f
\.


--
-- TOC entry 5040 (class 0 OID 26374)
-- Dependencies: 239
-- Data for Name: caja_sesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caja_sesion (id, usuario_id, abierta_en, cerrada_en, base_inicial, total_esperado, total_contado, diferencia, estado, observaciones) FROM stdin;
\.


--
-- TOC entry 5018 (class 0 OID 26138)
-- Dependencies: 217
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id, nombre, descripcion, activo, creado_en, prefijo_sku) FROM stdin;
1	Bebidas	Gaseosas, aguas, jugos y bebidas energizantes	t	2026-09-10 01:00:58.293923-05	BEB
2	Snacks y confitería	Paquetes, dulces y galletas	t	2026-09-10 01:00:58.293923-05	SNK
3	Víveres	Productos de la canasta básica	t	2026-09-10 01:00:58.293923-05	VIV
4	Aseo y hogar	Limpieza personal y del hogar	t	2026-09-10 01:00:58.293923-05	ASE
5	Papelería	Útiles escolares y de oficina	t	2026-09-10 01:00:58.293923-05	PAP
\.


--
-- TOC entry 5022 (class 0 OID 26186)
-- Dependencies: 221
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cliente (id, tipo_doc, num_doc, nombre, email, telefono, direccion, activo, creado_en) FROM stdin;
1	CC	222222222222	Consumidor final	\N	\N	\N	t	2026-09-10 01:00:58.293923-05
2	CC	1020304050	Laura Jiménez Ospina	laura.jimenez@correo.co	3105558842	Cra 13 # 45-21, Bogotá	t	2026-09-10 01:00:58.293923-05
3	CC	79654321	Andrés Mora Rincón	amora@correo.co	3122224411	Calle 68 # 11-30, Bogotá	t	2026-09-10 01:00:58.293923-05
4	NIT	900123456-7	Panadería La Espiga SAS	compras@laespiga.co	6014455667	Av 1 de Mayo # 40-12, Bogotá	t	2026-09-10 01:00:58.293923-05
5	CC	52987654	Diana Castaño Vélez	dcastano@correo.co	3009988776	Cra 7 # 120-45, Bogotá	t	2026-09-10 01:00:58.293923-05
6	CE	E1234567	Marco Antonelli	m.antonelli@correo.co	3151112233	Calle 93 # 15-08, Bogotá	t	2026-09-10 01:00:58.293923-05
\.


--
-- TOC entry 5034 (class 0 OID 26321)
-- Dependencies: 233
-- Data for Name: proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedor (id, nit, nombre, contacto, telefono, email, activo, creado_en) FROM stdin;
1	890900943-1	Distribuidora Andina SAS	Julián Peña	6013334455	ventas@andina.co	t	2026-09-10 01:00:58.293923-05
2	811004321-5	Comercial El Trigal Ltda	Sandra Rojas	6014447788	pedidos@eltrigal.co	t	2026-09-10 01:00:58.293923-05
3	830045678-9	Aseo Total SAS	Óscar Ruiz	6015556699	contacto@aseototal.co	t	2026-09-10 01:00:58.293923-05
\.


--
-- TOC entry 5036 (class 0 OID 26332)
-- Dependencies: 235
-- Data for Name: compra; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compra (id, proveedor_id, numero_factura, fecha, subtotal, total_iva, total, estado, creado_en, costo_incluye_iva) FROM stdin;
1	1	FV-1001	2026-07-20 21:14:46.792087-05	37250.00	7077.50	44327.50	RECIBIDA	2026-09-10 21:14:46.792087-05	f
2	2	FV-1002	2026-07-31 21:14:46.792087-05	72400.00	13756.00	86156.00	RECIBIDA	2026-09-10 21:14:46.792087-05	f
3	3	FV-1003	2026-08-08 21:14:46.792087-05	86500.00	16435.00	102935.00	RECIBIDA	2026-09-10 21:14:46.792087-05	f
4	1	FV-1004	2026-08-23 21:14:46.792087-05	74730.00	14198.70	88928.70	RECIBIDA	2026-09-10 21:14:46.792087-05	f
5	2	FV-1005	2026-09-01 21:14:46.792087-05	143000.00	2940.00	145940.00	RECIBIDA	2026-09-10 21:14:46.792087-05	f
6	3	FV-1006	2026-09-06 21:14:46.792087-05	271300.00	4450.00	275750.00	ANULADA	2026-09-10 21:14:46.792087-05	f
\.


--
-- TOC entry 5020 (class 0 OID 26152)
-- Dependencies: 219
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto (id, categoria_id, sku, nombre, descripcion, precio_venta, costo, iva_pct, stock_actual, stock_minimo, unidad_medida, activo, creado_en, actualizado_en) FROM stdin;
22	3	VIV-008	Azúcar blanca 1 kg	\N	4800.00	3700.00	5.00	26	10	KG	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
25	4	ASE-003	Detergente en polvo 900 g	\N	11200.00	8600.00	19.00	15	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
26	4	ASE-004	Blanqueador 1 L	\N	4500.00	3200.00	19.00	20	8	LT	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
27	4	ASE-005	Crema dental 100 ml	\N	6800.00	4900.00	19.00	5	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
28	4	ASE-006	Esponja para loza	\N	1600.00	950.00	19.00	40	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
19	3	VIV-005	Leche entera bolsa 1 L	\N	3900.00	3100.00	0.00	30	12	LT	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
20	3	VIV-006	Huevos AA bandeja x30	\N	21000.00	17500.00	0.00	12	4	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
21	3	VIV-007	Café molido 250 g	\N	11500.00	8900.00	5.00	14	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
30	5	PAP-002	Bolígrafo negro	\N	1200.00	700.00	19.00	74	30	UND	t	2026-09-10 01:00:58.293923-05	2026-09-11 14:17:29.057333-05
23	4	ASE-001	Jabón de tocador 110 g	\N	2700.00	1800.00	19.00	30	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 15:27:31.297032-05
24	4	ASE-002	Papel higiénico x4 rollos	\N	7900.00	5900.00	19.00	28	10	PAQ	t	2026-09-10 01:00:58.293923-05	2026-09-10 15:58:23.340315-05
17	3	VIV-003	Aceite de girasol 1 L	\N	12500.00	9800.00	5.00	23	6	LT	t	2026-09-10 01:00:58.293923-05	2026-09-11 14:29:05.96176-05
1	1	BEB-001	Gaseosa cola 400 ml	\N	2100.00	1450.00	19.00	54	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
2	1	BEB-002	Gaseosa naranja 400 ml	\N	2100.00	1450.00	19.00	43	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
4	1	BEB-004	Jugo de mango caja 200 ml	\N	1800.00	1200.00	19.00	39	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
5	1	BEB-005	Bebida energizante 250 ml	\N	4200.00	2900.00	19.00	28	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
6	1	BEB-006	Cerveza lata 330 ml	\N	3200.00	2200.00	19.00	83	24	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
8	2	SNK-001	Papas fritas naturales 45 g	\N	2500.00	1650.00	19.00	53	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
9	2	SNK-002	Papas fritas limón 45 g	\N	2500.00	1650.00	19.00	39	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
10	2	SNK-003	Galletas wafer vainilla	\N	1900.00	1250.00	19.00	48	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
11	2	SNK-004	Chocolatina con maní 40 g	\N	2200.00	1450.00	19.00	66	20	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
12	2	SNK-005	Maní salado 100 g	\N	3100.00	2050.00	19.00	33	8	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
13	2	SNK-006	Bombones surtidos	\N	350.00	210.00	19.00	218	60	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
14	2	SNK-007	Ponqué individual	\N	2800.00	1900.00	19.00	27	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
15	3	VIV-001	Arroz blanco 500 g	\N	3200.00	2400.00	0.00	65	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
16	3	VIV-002	Panela cuadrada 500 g	\N	3800.00	2900.00	0.00	27	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
18	3	VIV-004	Lentejas 500 g	\N	4100.00	3100.00	0.00	27	8	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 21:14:46.792087-05
29	5	PAP-001	Cuaderno cuadriculado 100 hojas	\N	5400.00	3900.00	19.00	23	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-12 21:21:56.753671-05
7	1	BEB-007	Té helado limón 400 ml	\N	2400.00	1600.00	19.00	21	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-12 21:29:08.365369-05
3	1	BEB-003	Agua sin gas 600 ml	\N	1500.00	950.00	19.00	68	24	UND	t	2026-09-10 01:00:58.293923-05	2026-09-12 22:01:26.916042-05
\.


--
-- TOC entry 5038 (class 0 OID 26354)
-- Dependencies: 237
-- Data for Name: compra_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compra_item (id, compra_id, producto_id, cantidad, costo_unitario, subtotal_linea) FROM stdin;
1	1	1	6.000	1450.00	8700.00
2	1	2	7.000	1450.00	10150.00
3	1	3	8.000	950.00	7600.00
4	1	4	9.000	1200.00	10800.00
5	2	5	10.000	2900.00	29000.00
6	2	6	11.000	2200.00	24200.00
7	2	7	12.000	1600.00	19200.00
8	3	8	13.000	1650.00	21450.00
9	3	9	14.000	1650.00	23100.00
10	3	10	15.000	1250.00	18750.00
11	3	11	16.000	1450.00	23200.00
12	4	12	17.000	2050.00	34850.00
13	4	13	18.000	210.00	3780.00
14	4	14	19.000	1900.00	36100.00
15	5	15	20.000	2400.00	48000.00
16	5	16	5.000	2900.00	14500.00
17	5	17	6.000	9800.00	58800.00
18	5	18	7.000	3100.00	21700.00
19	6	19	8.000	3100.00	24800.00
20	6	20	9.000	17500.00	157500.00
21	6	21	10.000	8900.00	89000.00
\.


--
-- TOC entry 5024 (class 0 OID 26202)
-- Dependencies: 223
-- Data for Name: venta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta (id, numero, cliente_id, fecha, subtotal, total_iva, total, metodo_pago, estado, observaciones, anulada_en, motivo_anula, creado_en, usuario_id, caja_sesion_id, precio_incluye_iva) FROM stdin;
1	F-000001	\N	2026-09-11 13:40:20.70912-05	4800.00	912.00	5712.00	EFECTIVO	PAGADA	\N	\N	\N	2026-09-11 13:40:20.70912-05	2	\N	t
2	F-000002	\N	2026-09-11 14:05:58.659911-05	1200.00	228.00	1428.00	EFECTIVO	PAGADA	\N	\N	\N	2026-09-11 14:05:58.659911-05	2	\N	t
3	F-000003	\N	2026-09-11 14:11:35.227157-05	1200.00	228.00	1428.00	EFECTIVO	PAGADA	\N	\N	\N	2026-09-11 14:11:35.227157-05	2	\N	t
4	F-000004	\N	2026-09-11 14:12:05.961205-05	1200.00	228.00	1428.00	EFECTIVO	ANULADA	\N	2026-09-11 14:17:29.422462-05	Mal dijitacion	2026-09-11 14:12:05.961205-05	2	\N	t
6	F-000006	\N	2026-09-12 21:21:56.753671-05	4537.82	862.18	5400.00	EFECTIVO	PAGADA	\N	\N	\N	2026-09-12 21:21:56.753671-05	2	\N	t
5	F-000005	6	2026-09-12 21:17:28.145821-05	42352.94	8047.06	50400.00	TARJETA	ANULADA	\N	2026-09-12 21:29:08.38656-05	El cajero dijito mal la venta	2026-09-12 21:17:28.145821-05	2	\N	t
7	F-000007	4	2026-09-12 21:56:21.118931-05	2521.01	478.99	3000.00	TARJETA	ANULADA	\N	2026-09-12 22:01:26.933239-05	damian	2026-09-12 21:56:21.118931-05	2	\N	t
\.


--
-- TOC entry 5030 (class 0 OID 26280)
-- Dependencies: 229
-- Data for Name: movimiento_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimiento_inventario (id, producto_id, tipo, cantidad, stock_anterior, stock_resultante, venta_id, usuario_id, motivo, fecha) FROM stdin;
1	1	COMPRA	6.000	48	54	\N	1	Compra FV-1001 (datos de ejemplo)	2026-07-20 21:14:46.792087-05
2	2	COMPRA	7.000	36	43	\N	1	Compra FV-1001 (datos de ejemplo)	2026-07-20 21:14:46.792087-05
3	3	COMPRA	8.000	60	68	\N	1	Compra FV-1001 (datos de ejemplo)	2026-07-20 21:14:46.792087-05
4	4	COMPRA	9.000	30	39	\N	1	Compra FV-1001 (datos de ejemplo)	2026-07-20 21:14:46.792087-05
5	5	COMPRA	10.000	18	28	\N	1	Compra FV-1002 (datos de ejemplo)	2026-07-31 21:14:46.792087-05
6	6	COMPRA	11.000	72	83	\N	1	Compra FV-1002 (datos de ejemplo)	2026-07-31 21:14:46.792087-05
7	7	COMPRA	12.000	9	21	\N	1	Compra FV-1002 (datos de ejemplo)	2026-07-31 21:14:46.792087-05
8	8	COMPRA	13.000	40	53	\N	1	Compra FV-1003 (datos de ejemplo)	2026-08-08 21:14:46.792087-05
9	9	COMPRA	14.000	25	39	\N	1	Compra FV-1003 (datos de ejemplo)	2026-08-08 21:14:46.792087-05
10	10	COMPRA	15.000	33	48	\N	1	Compra FV-1003 (datos de ejemplo)	2026-08-08 21:14:46.792087-05
11	11	COMPRA	16.000	50	66	\N	1	Compra FV-1003 (datos de ejemplo)	2026-08-08 21:14:46.792087-05
12	12	COMPRA	17.000	16	33	\N	1	Compra FV-1004 (datos de ejemplo)	2026-08-23 21:14:46.792087-05
13	13	COMPRA	18.000	200	218	\N	1	Compra FV-1004 (datos de ejemplo)	2026-08-23 21:14:46.792087-05
14	14	COMPRA	19.000	8	27	\N	1	Compra FV-1004 (datos de ejemplo)	2026-08-23 21:14:46.792087-05
15	15	COMPRA	20.000	45	65	\N	1	Compra FV-1005 (datos de ejemplo)	2026-09-01 21:14:46.792087-05
16	16	COMPRA	5.000	22	27	\N	1	Compra FV-1005 (datos de ejemplo)	2026-09-01 21:14:46.792087-05
17	17	COMPRA	6.000	18	24	\N	1	Compra FV-1005 (datos de ejemplo)	2026-09-01 21:14:46.792087-05
18	18	COMPRA	7.000	20	27	\N	1	Compra FV-1005 (datos de ejemplo)	2026-09-01 21:14:46.792087-05
19	19	COMPRA	8.000	30	38	\N	1	Compra FV-1006 (datos de ejemplo)	2026-09-06 21:14:46.792087-05
20	20	COMPRA	9.000	12	21	\N	1	Compra FV-1006 (datos de ejemplo)	2026-09-06 21:14:46.792087-05
21	21	COMPRA	10.000	14	24	\N	1	Compra FV-1006 (datos de ejemplo)	2026-09-06 21:14:46.792087-05
22	19	ANULACION	8.000	38	30	\N	1	Anulacion compra FV-1006: factura duplicada del proveedor	2026-09-06 23:14:46.792087-05
23	20	ANULACION	9.000	21	12	\N	1	Anulacion compra FV-1006: factura duplicada del proveedor	2026-09-06 23:14:46.792087-05
24	21	ANULACION	10.000	24	14	\N	1	Anulacion compra FV-1006: factura duplicada del proveedor	2026-09-06 23:14:46.792087-05
25	17	AJUSTE	1.000	24	25	\N	1	Ajuste manual de +1 desde la pantalla de productos	2026-09-10 21:32:43.475434-05
26	17	AJUSTE	1.000	25	24	\N	1	Ajuste manual de -1 desde la pantalla de productos	2026-09-10 21:32:44.614284-05
27	30	VENTA	4.000	80	76	1	2	Venta F-000001	2026-09-11 13:40:20.70912-05
28	30	VENTA	1.000	76	75	2	2	Venta F-000002	2026-09-11 14:05:58.659911-05
29	30	VENTA	1.000	75	74	3	2	Venta F-000003	2026-09-11 14:11:35.227157-05
30	30	VENTA	1.000	74	73	4	2	Venta F-000004	2026-09-11 14:12:05.961205-05
31	30	ANULACION	1.000	73	74	4	1	Anulacion venta F-000004: Mal dijitacion	2026-09-11 14:17:29.057333-05
32	17	AJUSTE	1.000	24	23	\N	1	Ajuste manual de -1 desde la pantalla de productos	2026-09-11 14:29:05.96176-05
33	7	VENTA	21.000	21	0	5	2	Venta F-000005	2026-09-12 21:17:28.145821-05
34	29	VENTA	1.000	24	23	6	2	Venta F-000006	2026-09-12 21:21:56.753671-05
35	7	ANULACION	21.000	0	21	5	1	Anulacion venta F-000005: El cajero dijito mal la venta	2026-09-12 21:29:08.365369-05
36	3	VENTA	2.000	68	66	7	2	Venta F-000007	2026-09-12 21:56:21.118931-05
37	3	ANULACION	2.000	66	68	7	1	Anulacion venta F-000007: damian	2026-09-12 22:01:26.916042-05
\.


--
-- TOC entry 5026 (class 0 OID 26235)
-- Dependencies: 225
-- Data for Name: venta_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta_item (id, venta_id, producto_id, cantidad, precio_unitario, iva_pct, subtotal_linea, iva_linea, total_linea) FROM stdin;
1	1	30	4.000	1200.00	19.00	4800.00	912.00	5712.00
2	2	30	1.000	1200.00	19.00	1200.00	228.00	1428.00
3	3	30	1.000	1200.00	19.00	1200.00	228.00	1428.00
4	4	30	1.000	1200.00	19.00	1200.00	228.00	1428.00
5	5	7	21.000	2400.00	19.00	42352.94	8047.06	50400.00
6	6	29	1.000	5400.00	19.00	4537.82	862.18	5400.00
7	7	3	2.000	1500.00	19.00	2521.01	478.99	3000.00
\.


--
-- TOC entry 5046 (class 0 OID 0)
-- Dependencies: 238
-- Name: caja_sesion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caja_sesion_id_seq', 1, false);


--
-- TOC entry 5047 (class 0 OID 0)
-- Dependencies: 216
-- Name: categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categoria_id_seq', 5, true);


--
-- TOC entry 5048 (class 0 OID 0)
-- Dependencies: 220
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_id_seq', 6, true);


--
-- TOC entry 5049 (class 0 OID 0)
-- Dependencies: 234
-- Name: compra_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compra_id_seq', 6, true);


--
-- TOC entry 5050 (class 0 OID 0)
-- Dependencies: 236
-- Name: compra_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compra_item_id_seq', 21, true);


--
-- TOC entry 5051 (class 0 OID 0)
-- Dependencies: 230
-- Name: configuracion_comercio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuracion_comercio_id_seq', 1, true);


--
-- TOC entry 5052 (class 0 OID 0)
-- Dependencies: 228
-- Name: movimiento_inventario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimiento_inventario_id_seq', 37, true);


--
-- TOC entry 5053 (class 0 OID 0)
-- Dependencies: 218
-- Name: producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producto_id_seq', 30, true);


--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 232
-- Name: proveedor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proveedor_id_seq', 3, true);


--
-- TOC entry 5055 (class 0 OID 0)
-- Dependencies: 226
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_seq', 2, true);


--
-- TOC entry 5056 (class 0 OID 0)
-- Dependencies: 222
-- Name: venta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_id_seq', 7, true);


--
-- TOC entry 5057 (class 0 OID 0)
-- Dependencies: 224
-- Name: venta_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_item_id_seq', 7, true);


--
-- TOC entry 5058 (class 0 OID 0)
-- Dependencies: 215
-- Name: venta_numero_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_numero_seq', 7, true);


-- Completed on 2026-09-12 22:42:13

--
-- PostgreSQL database dump complete
--

