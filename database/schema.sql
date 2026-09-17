--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

-- Started on 2026-09-12 22:32:33

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
-- TOC entry 242 (class 1255 OID 26135)
-- Name: set_actualizado_en(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_actualizado_en() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.actualizado_en = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_actualizado_en() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 239 (class 1259 OID 26374)
-- Name: caja_sesion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caja_sesion (
    id integer NOT NULL,
    usuario_id integer,
    abierta_en timestamp with time zone DEFAULT now() NOT NULL,
    cerrada_en timestamp with time zone,
    base_inicial numeric(12,2) DEFAULT 0 NOT NULL,
    total_esperado numeric(12,2),
    total_contado numeric(12,2),
    diferencia numeric(12,2),
    estado character varying(10) DEFAULT 'ABIERTA'::character varying NOT NULL,
    observaciones text,
    CONSTRAINT ck_caja_base CHECK ((base_inicial >= (0)::numeric)),
    CONSTRAINT ck_caja_estado CHECK (((estado)::text = ANY ((ARRAY['ABIERTA'::character varying, 'CERRADA'::character varying])::text[])))
);


ALTER TABLE public.caja_sesion OWNER TO postgres;

--
-- TOC entry 5103 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE caja_sesion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.caja_sesion IS 'Turno de caja. diferencia = total_contado - total_esperado.';


--
-- TOC entry 5104 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN caja_sesion.diferencia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.caja_sesion.diferencia IS 'Negativa = faltante, positiva = sobrante.';


--
-- TOC entry 238 (class 1259 OID 26373)
-- Name: caja_sesion_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caja_sesion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.caja_sesion_id_seq OWNER TO postgres;

--
-- TOC entry 5105 (class 0 OID 0)
-- Dependencies: 238
-- Name: caja_sesion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caja_sesion_id_seq OWNED BY public.caja_sesion.id;


--
-- TOC entry 217 (class 1259 OID 26138)
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id integer NOT NULL,
    nombre character varying(80) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    prefijo_sku character varying(5),
    CONSTRAINT ck_categoria_nombre_no_vacio CHECK ((length(TRIM(BOTH FROM nombre)) > 0))
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- TOC entry 5106 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE categoria; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.categoria IS 'Categorías del catálogo (Bebidas, Aseo, Papelería...).';


--
-- TOC entry 5107 (class 0 OID 0)
-- Dependencies: 217
-- Name: COLUMN categoria.activo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categoria.activo IS 'Borrado lógico: DELETE en la API pone FALSE, no elimina la fila.';


--
-- TOC entry 5108 (class 0 OID 0)
-- Dependencies: 217
-- Name: COLUMN categoria.prefijo_sku; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categoria.prefijo_sku IS 'Prefijo que digita el administrador. El backend genera BEB-001, BEB-002...';


--
-- TOC entry 216 (class 1259 OID 26137)
-- Name: categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_id_seq OWNER TO postgres;

--
-- TOC entry 5109 (class 0 OID 0)
-- Dependencies: 216
-- Name: categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_id_seq OWNED BY public.categoria.id;


--
-- TOC entry 221 (class 1259 OID 26186)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id integer NOT NULL,
    tipo_doc character varying(5) DEFAULT 'CC'::character varying NOT NULL,
    num_doc character varying(20) NOT NULL,
    nombre character varying(150) NOT NULL,
    email character varying(120),
    telefono character varying(30),
    direccion character varying(200),
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_cliente_tipo_doc CHECK (((tipo_doc)::text = ANY ((ARRAY['CC'::character varying, 'NIT'::character varying, 'CE'::character varying, 'TI'::character varying, 'PAS'::character varying])::text[])))
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 5110 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE cliente; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cliente IS 'Clientes del comercio. La fila id=1 es el consumidor final.';


--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN cliente.num_doc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cliente.num_doc IS 'Cédula o NIT. Único; valídenlo también con Pydantic.';


--
-- TOC entry 220 (class 1259 OID 26185)
-- Name: cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_seq OWNER TO postgres;

--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 220
-- Name: cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_seq OWNED BY public.cliente.id;


--
-- TOC entry 235 (class 1259 OID 26332)
-- Name: compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compra (
    id integer NOT NULL,
    proveedor_id integer NOT NULL,
    numero_factura character varying(40) NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    subtotal numeric(12,2) DEFAULT 0 NOT NULL,
    total_iva numeric(12,2) DEFAULT 0 NOT NULL,
    total numeric(12,2) DEFAULT 0 NOT NULL,
    estado character varying(10) DEFAULT 'RECIBIDA'::character varying NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    costo_incluye_iva boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_compra_estado CHECK (((estado)::text = ANY ((ARRAY['RECIBIDA'::character varying, 'ANULADA'::character varying])::text[])))
);


ALTER TABLE public.compra OWNER TO postgres;

--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN compra.costo_incluye_iva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.compra.costo_incluye_iva IS 'true: el costo que facturo el proveedor ya trae IVA. En ese caso compra_item.subtotal_linea guarda la base sin impuesto, y producto.costo tambien, porque el IVA de compra es descontable y no hace parte del valor del inventario.';


--
-- TOC entry 234 (class 1259 OID 26331)
-- Name: compra_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compra_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compra_id_seq OWNER TO postgres;

--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 234
-- Name: compra_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compra_id_seq OWNED BY public.compra.id;


--
-- TOC entry 237 (class 1259 OID 26354)
-- Name: compra_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compra_item (
    id integer NOT NULL,
    compra_id integer NOT NULL,
    producto_id integer NOT NULL,
    cantidad numeric(10,3) NOT NULL,
    costo_unitario numeric(12,2) NOT NULL,
    subtotal_linea numeric(12,2) NOT NULL,
    CONSTRAINT ck_compra_item_cantidad CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT ck_compra_item_costo CHECK ((costo_unitario >= (0)::numeric))
);


ALTER TABLE public.compra_item OWNER TO postgres;

--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE compra_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.compra_item IS 'Detalle de compra. Al registrarla, suma stock y genera movimiento tipo COMPRA.';


--
-- TOC entry 236 (class 1259 OID 26353)
-- Name: compra_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compra_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compra_item_id_seq OWNER TO postgres;

--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 236
-- Name: compra_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compra_item_id_seq OWNED BY public.compra_item.id;


--
-- TOC entry 231 (class 1259 OID 26308)
-- Name: configuracion_comercio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracion_comercio (
    id integer NOT NULL,
    razon_social character varying(150) NOT NULL,
    nit character varying(20) NOT NULL,
    direccion character varying(200),
    telefono character varying(30),
    prefijo_factura character varying(5) DEFAULT 'F'::character varying NOT NULL,
    resolucion_dian character varying(60),
    regimen character varying(30) DEFAULT 'NO RESPONSABLE DE IVA'::character varying NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    nombre_comercial character varying(150),
    logo_url character varying(500),
    email character varying(120),
    ciudad character varying(80),
    CONSTRAINT ck_config_fila_unica CHECK ((id = 1))
);


ALTER TABLE public.configuracion_comercio OWNER TO postgres;

--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE configuracion_comercio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.configuracion_comercio IS 'Datos del comercio para el encabezado del comprobante. Fila única (id=1).';


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN configuracion_comercio.nombre_comercial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.configuracion_comercio.nombre_comercial IS 'Nombre con el que se conoce el negocio. Si está vacío se muestra razon_social.';


--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN configuracion_comercio.logo_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.configuracion_comercio.logo_url IS 'URL pública del logo (bucket de Cloud Storage). La imagen NO se guarda en la base.';


--
-- TOC entry 230 (class 1259 OID 26307)
-- Name: configuracion_comercio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.configuracion_comercio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.configuracion_comercio_id_seq OWNER TO postgres;

--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 230
-- Name: configuracion_comercio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.configuracion_comercio_id_seq OWNED BY public.configuracion_comercio.id;


--
-- TOC entry 229 (class 1259 OID 26280)
-- Name: movimiento_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimiento_inventario (
    id integer NOT NULL,
    producto_id integer NOT NULL,
    tipo character varying(12) NOT NULL,
    cantidad numeric(10,3) NOT NULL,
    stock_anterior integer NOT NULL,
    stock_resultante integer NOT NULL,
    venta_id integer,
    usuario_id integer,
    motivo character varying(200),
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_mov_cantidad CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT ck_mov_stock CHECK ((stock_resultante >= 0)),
    CONSTRAINT ck_mov_tipo CHECK (((tipo)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SALIDA'::character varying, 'VENTA'::character varying, 'ANULACION'::character varying, 'AJUSTE'::character varying, 'COMPRA'::character varying])::text[])))
);


ALTER TABLE public.movimiento_inventario OWNER TO postgres;

--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE movimiento_inventario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.movimiento_inventario IS 'Kardex. Cada cambio de stock deja rastro; permite auditar y reconstruir el inventario.';


--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN movimiento_inventario.cantidad; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.movimiento_inventario.cantidad IS 'Siempre positiva. El signo lo determina la columna tipo.';


--
-- TOC entry 228 (class 1259 OID 26279)
-- Name: movimiento_inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimiento_inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimiento_inventario_id_seq OWNER TO postgres;

--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 228
-- Name: movimiento_inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimiento_inventario_id_seq OWNED BY public.movimiento_inventario.id;


--
-- TOC entry 219 (class 1259 OID 26152)
-- Name: producto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto (
    id integer NOT NULL,
    categoria_id integer NOT NULL,
    sku character varying(40) NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    precio_venta numeric(12,2) NOT NULL,
    costo numeric(12,2) DEFAULT 0 NOT NULL,
    iva_pct numeric(5,2) DEFAULT 19.00 NOT NULL,
    stock_actual integer DEFAULT 0 NOT NULL,
    stock_minimo integer DEFAULT 0 NOT NULL,
    unidad_medida character varying(15) DEFAULT 'UND'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_producto_costo CHECK ((costo >= (0)::numeric)),
    CONSTRAINT ck_producto_iva CHECK (((iva_pct >= (0)::numeric) AND (iva_pct <= (100)::numeric))),
    CONSTRAINT ck_producto_precio CHECK ((precio_venta >= (0)::numeric)),
    CONSTRAINT ck_producto_stock CHECK ((stock_actual >= 0)),
    CONSTRAINT ck_producto_stock_min CHECK ((stock_minimo >= 0)),
    CONSTRAINT ck_producto_unidad CHECK (((unidad_medida)::text = ANY ((ARRAY['UND'::character varying, 'KG'::character varying, 'LT'::character varying, 'MT'::character varying, 'CAJA'::character varying, 'PAQ'::character varying])::text[])))
);


ALTER TABLE public.producto OWNER TO postgres;

--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE producto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.producto IS 'Productos del comercio, con precio e inventario.';


--
-- TOC entry 5125 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN producto.sku; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.producto.sku IS 'Código interno o código de barras. Único en todo el comercio.';


--
-- TOC entry 5126 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN producto.precio_venta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.producto.precio_venta IS 'Precio SIN IVA, en pesos colombianos.';


--
-- TOC entry 5127 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN producto.iva_pct; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.producto.iva_pct IS 'IVA por producto: 19 general, 5 reducido, 0 exento/excluido.';


--
-- TOC entry 5128 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN producto.stock_minimo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.producto.stock_minimo IS 'Umbral para la alerta de reposición.';


--
-- TOC entry 218 (class 1259 OID 26151)
-- Name: producto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.producto_id_seq OWNER TO postgres;

--
-- TOC entry 5129 (class 0 OID 0)
-- Dependencies: 218
-- Name: producto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.producto_id_seq OWNED BY public.producto.id;


--
-- TOC entry 233 (class 1259 OID 26321)
-- Name: proveedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor (
    id integer NOT NULL,
    nit character varying(20) NOT NULL,
    nombre character varying(150) NOT NULL,
    contacto character varying(120),
    telefono character varying(30),
    email character varying(120),
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.proveedor OWNER TO postgres;

--
-- TOC entry 5130 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE proveedor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.proveedor IS 'Proveedores de mercancía.';


--
-- TOC entry 232 (class 1259 OID 26320)
-- Name: proveedor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.proveedor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.proveedor_id_seq OWNER TO postgres;

--
-- TOC entry 5131 (class 0 OID 0)
-- Dependencies: 232
-- Name: proveedor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.proveedor_id_seq OWNED BY public.proveedor.id;


--
-- TOC entry 227 (class 1259 OID 26259)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id integer NOT NULL,
    email character varying(120) NOT NULL,
    nombre character varying(120) NOT NULL,
    password_hash character varying(255) NOT NULL,
    rol character varying(10) DEFAULT 'CAJERO'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    ultimo_acceso timestamp with time zone,
    comercio_id integer DEFAULT 1 NOT NULL,
    foto_url text,
    debe_cambiar_password boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_usuario_rol CHECK (((rol)::text = ANY ((ARRAY['ADMIN'::character varying, 'CAJERO'::character varying])::text[])))
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 5132 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.usuario IS 'Operadores del POS. Autenticación con JWT.';


--
-- TOC entry 5133 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN usuario.password_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.usuario.password_hash IS 'Hash bcrypt. Jamás texto plano, ni siquiera en seed.sql.';


--
-- TOC entry 5134 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN usuario.foto_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.usuario.foto_url IS 'URL o ruta publica de la foto de perfil. Hoy vive en backend/static/fotos/, listo para migrar a Cloud Storage.';


--
-- TOC entry 5135 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN usuario.debe_cambiar_password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.usuario.debe_cambiar_password IS 'true = la contrasena es temporal (recien creada o reseteada por un ADMIN) y el frontend obliga a cambiarla antes de usar el resto de la app.';


--
-- TOC entry 226 (class 1259 OID 26258)
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_seq OWNER TO postgres;

--
-- TOC entry 5136 (class 0 OID 0)
-- Dependencies: 226
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- TOC entry 215 (class 1259 OID 26136)
-- Name: venta_numero_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venta_numero_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venta_numero_seq OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 26202)
-- Name: venta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venta (
    id integer NOT NULL,
    numero character varying(20) DEFAULT ('F-'::text || lpad((nextval('public.venta_numero_seq'::regclass))::text, 6, '0'::text)) NOT NULL,
    cliente_id integer,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    subtotal numeric(12,2) DEFAULT 0 NOT NULL,
    total_iva numeric(12,2) DEFAULT 0 NOT NULL,
    total numeric(12,2) DEFAULT 0 NOT NULL,
    metodo_pago character varying(20) DEFAULT 'EFECTIVO'::character varying NOT NULL,
    estado character varying(10) DEFAULT 'PAGADA'::character varying NOT NULL,
    observaciones text,
    anulada_en timestamp with time zone,
    motivo_anula character varying(200),
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id integer,
    caja_sesion_id integer,
    precio_incluye_iva boolean DEFAULT true NOT NULL,
    CONSTRAINT ck_venta_anulacion CHECK (((((estado)::text = 'ANULADA'::text) AND (anulada_en IS NOT NULL)) OR (((estado)::text = 'PAGADA'::text) AND (anulada_en IS NULL)))),
    CONSTRAINT ck_venta_estado CHECK (((estado)::text = ANY ((ARRAY['PAGADA'::character varying, 'ANULADA'::character varying])::text[]))),
    CONSTRAINT ck_venta_iva CHECK ((total_iva >= (0)::numeric)),
    CONSTRAINT ck_venta_metodo CHECK (((metodo_pago)::text = ANY ((ARRAY['EFECTIVO'::character varying, 'TARJETA'::character varying, 'TRANSFERENCIA'::character varying, 'MIXTO'::character varying])::text[]))),
    CONSTRAINT ck_venta_subtotal CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT ck_venta_total CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.venta OWNER TO postgres;

--
-- TOC entry 5137 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE venta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.venta IS 'Encabezado de venta. Nunca se borra físicamente: se anula.';


--
-- TOC entry 5138 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN venta.numero; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta.numero IS 'Consecutivo generado por la secuencia venta_numero_seq (F-000001).';


--
-- TOC entry 5139 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN venta.cliente_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta.cliente_id IS 'NULL = consumidor final sin identificar.';


--
-- TOC entry 5140 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN venta.subtotal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta.subtotal IS 'Suma de líneas SIN IVA. Se calcula en el backend, jamás se recibe del frontend.';


--
-- TOC entry 5141 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN venta.precio_incluye_iva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta.precio_incluye_iva IS 'true: precio_unitario de cada linea ya trae el IVA y la factura lo desglosa. false: precio_unitario es la base y el IVA se suma encima.';


--
-- TOC entry 222 (class 1259 OID 26201)
-- Name: venta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venta_id_seq OWNER TO postgres;

--
-- TOC entry 5142 (class 0 OID 0)
-- Dependencies: 222
-- Name: venta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venta_id_seq OWNED BY public.venta.id;


--
-- TOC entry 225 (class 1259 OID 26235)
-- Name: venta_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venta_item (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    producto_id integer NOT NULL,
    cantidad numeric(10,3) NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    iva_pct numeric(5,2) NOT NULL,
    subtotal_linea numeric(12,2) NOT NULL,
    iva_linea numeric(12,2) NOT NULL,
    total_linea numeric(12,2) NOT NULL,
    CONSTRAINT ck_item_cantidad CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT ck_item_iva CHECK (((iva_pct >= (0)::numeric) AND (iva_pct <= (100)::numeric))),
    CONSTRAINT ck_item_precio CHECK ((precio_unitario >= (0)::numeric))
);


ALTER TABLE public.venta_item OWNER TO postgres;

--
-- TOC entry 5143 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE venta_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.venta_item IS 'Detalle de la venta. Relación 1:N con venta.';


--
-- TOC entry 5144 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN venta_item.precio_unitario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta_item.precio_unitario IS 'COPIA CONGELADA del precio al momento de vender. Si el producto sube de precio mañana, esta factura no cambia.';


--
-- TOC entry 5145 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN venta_item.iva_pct; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.venta_item.iva_pct IS 'También congelado: las tarifas de IVA cambian por ley.';


--
-- TOC entry 224 (class 1259 OID 26234)
-- Name: venta_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venta_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venta_item_id_seq OWNER TO postgres;

--
-- TOC entry 5146 (class 0 OID 0)
-- Dependencies: 224
-- Name: venta_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venta_item_id_seq OWNED BY public.venta_item.id;


--
-- TOC entry 240 (class 1259 OID 26398)
-- Name: vw_productos_bajo_stock; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_productos_bajo_stock AS
 SELECT p.id,
    p.sku,
    p.nombre,
    c.nombre AS categoria,
    p.stock_actual,
    p.stock_minimo,
    (p.stock_minimo - p.stock_actual) AS faltante
   FROM (public.producto p
     JOIN public.categoria c ON ((c.id = p.categoria_id)))
  WHERE ((p.activo = true) AND (p.stock_actual <= p.stock_minimo))
  ORDER BY (p.stock_minimo - p.stock_actual) DESC;


ALTER VIEW public.vw_productos_bajo_stock OWNER TO postgres;

--
-- TOC entry 5147 (class 0 OID 0)
-- Dependencies: 240
-- Name: VIEW vw_productos_bajo_stock; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_productos_bajo_stock IS 'Alerta de reposición: productos en o por debajo del stock mínimo.';


--
-- TOC entry 241 (class 1259 OID 26403)
-- Name: vw_ventas_por_dia; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_ventas_por_dia AS
 SELECT (date_trunc('day'::text, fecha))::date AS dia,
    count(*) AS num_ventas,
    sum(subtotal) AS subtotal,
    sum(total_iva) AS iva,
    sum(total) AS total
   FROM public.venta v
  WHERE ((estado)::text = 'PAGADA'::text)
  GROUP BY ((date_trunc('day'::text, fecha))::date)
  ORDER BY ((date_trunc('day'::text, fecha))::date) DESC;


ALTER VIEW public.vw_ventas_por_dia OWNER TO postgres;

--
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 241
-- Name: VIEW vw_ventas_por_dia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_ventas_por_dia IS 'Resumen diario de ventas pagadas. Excluye las anuladas.';


--
-- TOC entry 4851 (class 2604 OID 26377)
-- Name: caja_sesion id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caja_sesion ALTER COLUMN id SET DEFAULT nextval('public.caja_sesion_id_seq'::regclass);


--
-- TOC entry 4800 (class 2604 OID 26141)
-- Name: categoria id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id SET DEFAULT nextval('public.categoria_id_seq'::regclass);


--
-- TOC entry 4812 (class 2604 OID 26189)
-- Name: cliente id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id SET DEFAULT nextval('public.cliente_id_seq'::regclass);


--
-- TOC entry 4842 (class 2604 OID 26335)
-- Name: compra id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra ALTER COLUMN id SET DEFAULT nextval('public.compra_id_seq'::regclass);


--
-- TOC entry 4850 (class 2604 OID 26357)
-- Name: compra_item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra_item ALTER COLUMN id SET DEFAULT nextval('public.compra_item_id_seq'::regclass);


--
-- TOC entry 4835 (class 2604 OID 26311)
-- Name: configuracion_comercio id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_comercio ALTER COLUMN id SET DEFAULT nextval('public.configuracion_comercio_id_seq'::regclass);


--
-- TOC entry 4833 (class 2604 OID 26283)
-- Name: movimiento_inventario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario ALTER COLUMN id SET DEFAULT nextval('public.movimiento_inventario_id_seq'::regclass);


--
-- TOC entry 4803 (class 2604 OID 26155)
-- Name: producto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto ALTER COLUMN id SET DEFAULT nextval('public.producto_id_seq'::regclass);


--
-- TOC entry 4839 (class 2604 OID 26324)
-- Name: proveedor id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor ALTER COLUMN id SET DEFAULT nextval('public.proveedor_id_seq'::regclass);


--
-- TOC entry 4827 (class 2604 OID 26262)
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- TOC entry 4816 (class 2604 OID 26205)
-- Name: venta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta ALTER COLUMN id SET DEFAULT nextval('public.venta_id_seq'::regclass);


--
-- TOC entry 4826 (class 2604 OID 26238)
-- Name: venta_item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_item ALTER COLUMN id SET DEFAULT nextval('public.venta_item_id_seq'::regclass);


--
-- TOC entry 4936 (class 2606 OID 26386)
-- Name: caja_sesion caja_sesion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caja_sesion
    ADD CONSTRAINT caja_sesion_pkey PRIMARY KEY (id);


--
-- TOC entry 4883 (class 2606 OID 26150)
-- Name: categoria categoria_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_nombre_key UNIQUE (nombre);


--
-- TOC entry 4885 (class 2606 OID 26148)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 26199)
-- Name: cliente cliente_num_doc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_num_doc_key UNIQUE (num_doc);


--
-- TOC entry 4896 (class 2606 OID 26197)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id);


--
-- TOC entry 4933 (class 2606 OID 26361)
-- Name: compra_item compra_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra_item
    ADD CONSTRAINT compra_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4928 (class 2606 OID 26344)
-- Name: compra compra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_pkey PRIMARY KEY (id);


--
-- TOC entry 4922 (class 2606 OID 26319)
-- Name: configuracion_comercio configuracion_comercio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_comercio
    ADD CONSTRAINT configuracion_comercio_pkey PRIMARY KEY (id);


--
-- TOC entry 4920 (class 2606 OID 26289)
-- Name: movimiento_inventario movimiento_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT movimiento_inventario_pkey PRIMARY KEY (id);


--
-- TOC entry 4890 (class 2606 OID 26173)
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);


--
-- TOC entry 4892 (class 2606 OID 26175)
-- Name: producto producto_sku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_sku_key UNIQUE (sku);


--
-- TOC entry 4924 (class 2606 OID 26330)
-- Name: proveedor proveedor_nit_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_nit_key UNIQUE (nit);


--
-- TOC entry 4926 (class 2606 OID 26328)
-- Name: proveedor proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4931 (class 2606 OID 26346)
-- Name: compra uq_compra_proveedor_factura; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT uq_compra_proveedor_factura UNIQUE (proveedor_id, numero_factura);


--
-- TOC entry 4909 (class 2606 OID 26245)
-- Name: venta_item uq_item_venta_producto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_item
    ADD CONSTRAINT uq_item_venta_producto UNIQUE (venta_id, producto_id);


--
-- TOC entry 4914 (class 2606 OID 26272)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 4916 (class 2606 OID 26270)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 4911 (class 2606 OID 26243)
-- Name: venta_item venta_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_item
    ADD CONSTRAINT venta_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4903 (class 2606 OID 26225)
-- Name: venta venta_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT venta_numero_key UNIQUE (numero);


--
-- TOC entry 4905 (class 2606 OID 26223)
-- Name: venta venta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT venta_pkey PRIMARY KEY (id);


--
-- TOC entry 4897 (class 1259 OID 26200)
-- Name: idx_cliente_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cliente_nombre ON public.cliente USING btree (lower((nombre)::text));


--
-- TOC entry 4929 (class 1259 OID 26352)
-- Name: idx_compra_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compra_fecha ON public.compra USING btree (fecha DESC);


--
-- TOC entry 4934 (class 1259 OID 26372)
-- Name: idx_compra_item_compra; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compra_item_compra ON public.compra_item USING btree (compra_id);


--
-- TOC entry 4906 (class 1259 OID 26257)
-- Name: idx_item_producto; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_producto ON public.venta_item USING btree (producto_id);


--
-- TOC entry 4907 (class 1259 OID 26256)
-- Name: idx_item_venta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_venta ON public.venta_item USING btree (venta_id);


--
-- TOC entry 4917 (class 1259 OID 26305)
-- Name: idx_mov_producto_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mov_producto_fecha ON public.movimiento_inventario USING btree (producto_id, fecha DESC);


--
-- TOC entry 4918 (class 1259 OID 26306)
-- Name: idx_mov_venta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mov_venta ON public.movimiento_inventario USING btree (venta_id);


--
-- TOC entry 4886 (class 1259 OID 26182)
-- Name: idx_producto_activo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_producto_activo ON public.producto USING btree (activo);


--
-- TOC entry 4887 (class 1259 OID 26181)
-- Name: idx_producto_categoria; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_producto_categoria ON public.producto USING btree (categoria_id);


--
-- TOC entry 4888 (class 1259 OID 26183)
-- Name: idx_producto_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_producto_nombre ON public.producto USING btree (lower((nombre)::text));


--
-- TOC entry 4912 (class 1259 OID 26414)
-- Name: idx_usuario_comercio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuario_comercio ON public.usuario USING btree (comercio_id);


--
-- TOC entry 4898 (class 1259 OID 26233)
-- Name: idx_venta_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venta_cliente ON public.venta USING btree (cliente_id);


--
-- TOC entry 4899 (class 1259 OID 26232)
-- Name: idx_venta_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venta_estado ON public.venta USING btree (estado);


--
-- TOC entry 4900 (class 1259 OID 26231)
-- Name: idx_venta_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venta_fecha ON public.venta USING btree (fecha DESC);


--
-- TOC entry 4901 (class 1259 OID 26278)
-- Name: idx_venta_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venta_usuario ON public.venta USING btree (usuario_id);


--
-- TOC entry 4937 (class 1259 OID 26392)
-- Name: uq_caja_una_abierta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_caja_una_abierta ON public.caja_sesion USING btree (estado) WHERE ((estado)::text = 'ABIERTA'::text);


--
-- TOC entry 4952 (class 2620 OID 26184)
-- Name: producto trg_producto_actualizado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_producto_actualizado BEFORE UPDATE ON public.producto FOR EACH ROW EXECUTE FUNCTION public.set_actualizado_en();


--
-- TOC entry 4951 (class 2606 OID 26387)
-- Name: caja_sesion fk_caja_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caja_sesion
    ADD CONSTRAINT fk_caja_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE SET NULL;


--
-- TOC entry 4949 (class 2606 OID 26362)
-- Name: compra_item fk_compra_item_compra; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra_item
    ADD CONSTRAINT fk_compra_item_compra FOREIGN KEY (compra_id) REFERENCES public.compra(id) ON DELETE CASCADE;


--
-- TOC entry 4950 (class 2606 OID 26367)
-- Name: compra_item fk_compra_item_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra_item
    ADD CONSTRAINT fk_compra_item_producto FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON DELETE RESTRICT;


--
-- TOC entry 4948 (class 2606 OID 26347)
-- Name: compra fk_compra_proveedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_proveedor FOREIGN KEY (proveedor_id) REFERENCES public.proveedor(id) ON DELETE RESTRICT;


--
-- TOC entry 4942 (class 2606 OID 26251)
-- Name: venta_item fk_item_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_item
    ADD CONSTRAINT fk_item_producto FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON DELETE RESTRICT;


--
-- TOC entry 4943 (class 2606 OID 26246)
-- Name: venta_item fk_item_venta; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_item
    ADD CONSTRAINT fk_item_venta FOREIGN KEY (venta_id) REFERENCES public.venta(id) ON DELETE CASCADE;


--
-- TOC entry 4945 (class 2606 OID 26290)
-- Name: movimiento_inventario fk_mov_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT fk_mov_producto FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON DELETE RESTRICT;


--
-- TOC entry 4946 (class 2606 OID 26300)
-- Name: movimiento_inventario fk_mov_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT fk_mov_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE SET NULL;


--
-- TOC entry 4947 (class 2606 OID 26295)
-- Name: movimiento_inventario fk_mov_venta; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT fk_mov_venta FOREIGN KEY (venta_id) REFERENCES public.venta(id) ON DELETE SET NULL;


--
-- TOC entry 4938 (class 2606 OID 26176)
-- Name: producto fk_producto_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES public.categoria(id) ON DELETE RESTRICT;


--
-- TOC entry 4944 (class 2606 OID 26409)
-- Name: usuario fk_usuario_comercio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT fk_usuario_comercio FOREIGN KEY (comercio_id) REFERENCES public.configuracion_comercio(id) ON DELETE RESTRICT;


--
-- TOC entry 4939 (class 2606 OID 26393)
-- Name: venta fk_venta_caja; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT fk_venta_caja FOREIGN KEY (caja_sesion_id) REFERENCES public.caja_sesion(id) ON DELETE SET NULL;


--
-- TOC entry 4940 (class 2606 OID 26226)
-- Name: venta fk_venta_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT fk_venta_cliente FOREIGN KEY (cliente_id) REFERENCES public.cliente(id) ON DELETE SET NULL;


--
-- TOC entry 4941 (class 2606 OID 26273)
-- Name: venta fk_venta_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT fk_venta_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE SET NULL;


-- Completed on 2026-09-12 22:32:34

--
-- PostgreSQL database dump complete
--

