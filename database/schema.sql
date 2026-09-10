--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

-- Started on 2026-09-10 15:43:29

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
-- TOC entry 5119 (class 0 OID 26374)
-- Dependencies: 239
-- Data for Name: caja_sesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caja_sesion (id, usuario_id, abierta_en, cerrada_en, base_inicial, total_esperado, total_contado, diferencia, estado, observaciones) FROM stdin;
\.


--
-- TOC entry 5097 (class 0 OID 26138)
-- Dependencies: 217
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id, nombre, descripcion, activo, creado_en) FROM stdin;
1	Bebidas	Gaseosas, aguas, jugos y bebidas energizantes	t	2026-09-10 01:00:58.293923-05
2	Snacks y confitería	Paquetes, dulces y galletas	t	2026-09-10 01:00:58.293923-05
3	Víveres	Productos de la canasta básica	t	2026-09-10 01:00:58.293923-05
4	Aseo y hogar	Limpieza personal y del hogar	t	2026-09-10 01:00:58.293923-05
5	Papelería	Útiles escolares y de oficina	t	2026-09-10 01:00:58.293923-05
\.


--
-- TOC entry 5101 (class 0 OID 26186)
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
-- TOC entry 5115 (class 0 OID 26332)
-- Dependencies: 235
-- Data for Name: compra; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compra (id, proveedor_id, numero_factura, fecha, subtotal, total_iva, total, estado, creado_en) FROM stdin;
\.


--
-- TOC entry 5117 (class 0 OID 26354)
-- Dependencies: 237
-- Data for Name: compra_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compra_item (id, compra_id, producto_id, cantidad, costo_unitario, subtotal_linea) FROM stdin;
\.


--
-- TOC entry 5111 (class 0 OID 26308)
-- Dependencies: 231
-- Data for Name: configuracion_comercio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracion_comercio (id, razon_social, nit, direccion, telefono, prefijo_factura, resolucion_dian, regimen, actualizado_en, nombre_comercial, logo_url, email, ciudad) FROM stdin;
1	Comercializadora Cuadre S.A.S.	901234567-8	Calle 45 # 12-30	3001234567	F	\N	NO RESPONSABLE DE IVA	2026-09-10 15:01:16.415731-05	Cuadre POS	https://media.istockphoto.com/id/1201144331/es/vector/logotipo-de-icon-design-element-para-la-empresa-de-innovaci%C3%B3n-tecnol%C3%B3gica-icono-tecnol%C3%B3gico.jpg?s=2048x2048&w=is&k=20&c=NTaJ1oDHiv5LcKfQDYERiw_MrDXdkCARng2m8qQXa1c=	contacto@cuadrepos.co	Bogotá D.C.
\.


--
-- TOC entry 5109 (class 0 OID 26280)
-- Dependencies: 229
-- Data for Name: movimiento_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimiento_inventario (id, producto_id, tipo, cantidad, stock_anterior, stock_resultante, venta_id, usuario_id, motivo, fecha) FROM stdin;
\.


--
-- TOC entry 5099 (class 0 OID 26152)
-- Dependencies: 219
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto (id, categoria_id, sku, nombre, descripcion, precio_venta, costo, iva_pct, stock_actual, stock_minimo, unidad_medida, activo, creado_en, actualizado_en) FROM stdin;
1	1	BEB-001	Gaseosa cola 400 ml	\N	2100.00	1450.00	19.00	48	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
2	1	BEB-002	Gaseosa naranja 400 ml	\N	2100.00	1450.00	19.00	36	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
3	1	BEB-003	Agua sin gas 600 ml	\N	1500.00	950.00	19.00	60	24	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
4	1	BEB-004	Jugo de mango caja 200 ml	\N	1800.00	1200.00	19.00	30	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
5	1	BEB-005	Bebida energizante 250 ml	\N	4200.00	2900.00	19.00	18	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
6	1	BEB-006	Cerveza lata 330 ml	\N	3200.00	2200.00	19.00	72	24	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
7	1	BEB-007	Té helado limón 400 ml	\N	2400.00	1600.00	19.00	9	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
8	2	SNK-001	Papas fritas naturales 45 g	\N	2500.00	1650.00	19.00	40	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
9	2	SNK-002	Papas fritas limón 45 g	\N	2500.00	1650.00	19.00	25	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
10	2	SNK-003	Galletas wafer vainilla	\N	1900.00	1250.00	19.00	33	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
11	2	SNK-004	Chocolatina con maní 40 g	\N	2200.00	1450.00	19.00	50	20	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
12	2	SNK-005	Maní salado 100 g	\N	3100.00	2050.00	19.00	16	8	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
13	2	SNK-006	Bombones surtidos	\N	350.00	210.00	19.00	200	60	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
14	2	SNK-007	Ponqué individual	\N	2800.00	1900.00	19.00	6	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
15	3	VIV-001	Arroz blanco 500 g	\N	3200.00	2400.00	0.00	45	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
16	3	VIV-002	Panela cuadrada 500 g	\N	3800.00	2900.00	0.00	22	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
17	3	VIV-003	Aceite de girasol 1 L	\N	12500.00	9800.00	5.00	18	6	LT	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
18	3	VIV-004	Lentejas 500 g	\N	4100.00	3100.00	0.00	20	8	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
19	3	VIV-005	Leche entera bolsa 1 L	\N	3900.00	3100.00	0.00	30	12	LT	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
20	3	VIV-006	Huevos AA bandeja x30	\N	21000.00	17500.00	0.00	12	4	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
21	3	VIV-007	Café molido 250 g	\N	11500.00	8900.00	5.00	14	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
22	3	VIV-008	Azúcar blanca 1 kg	\N	4800.00	3700.00	5.00	26	10	KG	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
25	4	ASE-003	Detergente en polvo 900 g	\N	11200.00	8600.00	19.00	15	6	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
26	4	ASE-004	Blanqueador 1 L	\N	4500.00	3200.00	19.00	20	8	LT	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
27	4	ASE-005	Crema dental 100 ml	\N	6800.00	4900.00	19.00	5	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
28	4	ASE-006	Esponja para loza	\N	1600.00	950.00	19.00	40	15	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
29	5	PAP-001	Cuaderno cuadriculado 100 hojas	\N	5400.00	3900.00	19.00	24	10	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
30	5	PAP-002	Bolígrafo negro	\N	1200.00	700.00	19.00	80	30	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 01:00:58.293923-05
23	4	ASE-001	Jabón de tocador 110 g	\N	2700.00	1800.00	19.00	30	12	UND	t	2026-09-10 01:00:58.293923-05	2026-09-10 15:27:31.297032-05
24	4	ASE-002	Papel higiénico x4 rollos	\N	7900.00	5900.00	19.00	28	10	PAQ	f	2026-09-10 01:00:58.293923-05	2026-09-10 15:27:34.683476-05
\.


--
-- TOC entry 5113 (class 0 OID 26321)
-- Dependencies: 233
-- Data for Name: proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedor (id, nit, nombre, contacto, telefono, email, activo, creado_en) FROM stdin;
1	890900943-1	Distribuidora Andina SAS	Julián Peña	6013334455	ventas@andina.co	t	2026-09-10 01:00:58.293923-05
2	811004321-5	Comercial El Trigal Ltda	Sandra Rojas	6014447788	pedidos@eltrigal.co	t	2026-09-10 01:00:58.293923-05
3	830045678-9	Aseo Total SAS	Óscar Ruiz	6015556699	contacto@aseototal.co	t	2026-09-10 01:00:58.293923-05
\.


--
-- TOC entry 5107 (class 0 OID 26259)
-- Dependencies: 227
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id, email, nombre, password_hash, rol, activo, creado_en, ultimo_acceso, comercio_id) FROM stdin;
2	cajero@cuadrepos.co	Cajero demo	$2b$12$sJSDTp95vhDls5pshxIiNunh9JKcP.z4JisDOBF2DwhssEvAuDLlG	CAJERO	t	2026-09-10 01:00:58.293923-05	\N	1
1	admin@cuadrepos.co	Administrador demo	$2b$12$1.M8rSma4qX1DZsrVjnNoet2A.yT.Z8cKEUZ7wPQSWoR8b/EX/nZu	ADMIN	t	2026-09-10 01:00:58.293923-05	2026-09-10 20:18:41.595383-05	1
\.


--
-- TOC entry 5103 (class 0 OID 26202)
-- Dependencies: 223
-- Data for Name: venta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta (id, numero, cliente_id, fecha, subtotal, total_iva, total, metodo_pago, estado, observaciones, anulada_en, motivo_anula, creado_en, usuario_id, caja_sesion_id) FROM stdin;
\.


--
-- TOC entry 5105 (class 0 OID 26235)
-- Dependencies: 225
-- Data for Name: venta_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta_item (id, venta_id, producto_id, cantidad, precio_unitario, iva_pct, subtotal_linea, iva_linea, total_linea) FROM stdin;
\.


--
-- TOC entry 5166 (class 0 OID 0)
-- Dependencies: 238
-- Name: caja_sesion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caja_sesion_id_seq', 1, false);


--
-- TOC entry 5167 (class 0 OID 0)
-- Dependencies: 216
-- Name: categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categoria_id_seq', 5, true);


--
-- TOC entry 5168 (class 0 OID 0)
-- Dependencies: 220
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_id_seq', 6, true);


--
-- TOC entry 5169 (class 0 OID 0)
-- Dependencies: 234
-- Name: compra_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compra_id_seq', 1, false);


--
-- TOC entry 5170 (class 0 OID 0)
-- Dependencies: 236
-- Name: compra_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compra_item_id_seq', 1, false);


--
-- TOC entry 5171 (class 0 OID 0)
-- Dependencies: 230
-- Name: configuracion_comercio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuracion_comercio_id_seq', 1, true);


--
-- TOC entry 5172 (class 0 OID 0)
-- Dependencies: 228
-- Name: movimiento_inventario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimiento_inventario_id_seq', 1, false);


--
-- TOC entry 5173 (class 0 OID 0)
-- Dependencies: 218
-- Name: producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producto_id_seq', 30, true);


--
-- TOC entry 5174 (class 0 OID 0)
-- Dependencies: 232
-- Name: proveedor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proveedor_id_seq', 3, true);


--
-- TOC entry 5175 (class 0 OID 0)
-- Dependencies: 226
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_seq', 2, true);


--
-- TOC entry 5176 (class 0 OID 0)
-- Dependencies: 222
-- Name: venta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_id_seq', 1, false);


--
-- TOC entry 5177 (class 0 OID 0)
-- Dependencies: 224
-- Name: venta_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_item_id_seq', 1, false);


--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 215
-- Name: venta_numero_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_numero_seq', 1, false);


-- Completed on 2026-09-10 15:43:30

--
-- PostgreSQL database dump complete
--

