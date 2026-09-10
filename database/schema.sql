-- =============================================================================
--  CUADRE POS — Esquema de base de datos
--  Motor      : PostgreSQL 16 (Google Cloud SQL)
--  Proyecto   : Actividad integradora — Desarrollo de aplicaciones en la nube
--  Archivo    : database/schema.sql
--
--  ORGANIZACIÓN DEL ARCHIVO
--    BLOQUE 0 — Utilidades (funciones y secuencias)
--    BLOQUE 1 — NÚCLEO      : obligatorio, cumple el mínimo de la guía
--    BLOQUE 2 — EXTRAS      : recomendados (kardex y usuarios/roles)
--    BLOQUE 3 — OPCIONALES  : compras, caja y configuración del comercio
--    BLOQUE 4 — Vistas de apoyo
--
--  Cada bloque es independiente: si deciden recortar el alcance, borren el
--  bloque completo de abajo hacia arriba (4 → 3 → 2) sin tocar el NÚCLEO.
--
--  CONVENCIONES
--    · Dinero      -> NUMERIC(12,2). NUNCA float/real: introduce errores de
--                     redondeo en los totales de la factura.
--    · Cantidades  -> NUMERIC(10,3) para permitir venta por peso (kg, lt).
--    · Fechas      -> TIMESTAMPTZ (con zona horaria). Cloud SQL corre en UTC.
--    · Estados     -> VARCHAR + CHECK en vez de tipo ENUM nativo: agregar un
--                     valor nuevo es un ALTER simple y no rompe el ORM.
--    · Borrado     -> lógico (columna `activo` / estado 'ANULADA'). El
--                     histórico de ventas nunca se destruye.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SOLO PARA DESARROLLO: descomentar para reconstruir la base desde cero.
-- ¡No ejecutar en la instancia que van a sustentar!
-- -----------------------------------------------------------------------------
-- DROP VIEW  IF EXISTS vw_productos_bajo_stock, vw_ventas_por_dia CASCADE;
-- DROP TABLE IF EXISTS compra_item, compra, proveedor, caja_sesion,
--                      configuracion_comercio, movimiento_inventario,
--                      venta_item, venta, producto, categoria, cliente,
--                      usuario CASCADE;
-- DROP SEQUENCE IF EXISTS venta_numero_seq;
-- DROP FUNCTION IF EXISTS set_actualizado_en();


-- =============================================================================
-- BLOQUE 0 — UTILIDADES
-- =============================================================================

-- Mantiene `actualizado_en` al día sin que el backend tenga que acordarse.
CREATE OR REPLACE FUNCTION set_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Consecutivo de facturación. Postgres garantiza que dos ventas simultáneas
-- nunca reciban el mismo número, cosa que un MAX(id)+1 en el backend no puede
-- garantizar. Formato resultante: F-000001, F-000002, ...
CREATE SEQUENCE venta_numero_seq START WITH 1 INCREMENT BY 1;


-- =============================================================================
-- BLOQUE 1 — NÚCLEO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- categoria — agrupa el catálogo de productos
-- -----------------------------------------------------------------------------
CREATE TABLE categoria (
    id           SERIAL       PRIMARY KEY,
    nombre       VARCHAR(80)  NOT NULL UNIQUE,
    descripcion  TEXT,
    activo       BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT ck_categoria_nombre_no_vacio CHECK (length(trim(nombre)) > 0)
);

COMMENT ON TABLE  categoria        IS 'Categorías del catálogo (Bebidas, Aseo, Papelería...).';
COMMENT ON COLUMN categoria.activo IS 'Borrado lógico: DELETE en la API pone FALSE, no elimina la fila.';


-- -----------------------------------------------------------------------------
-- producto — catálogo e inventario
-- -----------------------------------------------------------------------------
CREATE TABLE producto (
    id              SERIAL         PRIMARY KEY,
    categoria_id    INTEGER        NOT NULL,
    sku             VARCHAR(40)    NOT NULL UNIQUE,
    nombre          VARCHAR(150)   NOT NULL,
    descripcion     TEXT,
    precio_venta    NUMERIC(12,2)  NOT NULL,
    costo           NUMERIC(12,2)  NOT NULL DEFAULT 0,
    iva_pct         NUMERIC(5,2)   NOT NULL DEFAULT 19.00,
    stock_actual    INTEGER        NOT NULL DEFAULT 0,
    stock_minimo    INTEGER        NOT NULL DEFAULT 0,
    unidad_medida   VARCHAR(15)    NOT NULL DEFAULT 'UND',
    activo          BOOLEAN        NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMPTZ    NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id) REFERENCES categoria (id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_producto_precio     CHECK (precio_venta >= 0),
    CONSTRAINT ck_producto_costo      CHECK (costo        >= 0),
    CONSTRAINT ck_producto_iva        CHECK (iva_pct      >= 0 AND iva_pct <= 100),
    CONSTRAINT ck_producto_stock      CHECK (stock_actual >= 0),
    CONSTRAINT ck_producto_stock_min  CHECK (stock_minimo >= 0),
    CONSTRAINT ck_producto_unidad     CHECK (unidad_medida IN ('UND','KG','LT','MT','CAJA','PAQ'))
);

CREATE INDEX idx_producto_categoria ON producto (categoria_id);
CREATE INDEX idx_producto_activo    ON producto (activo);
-- Acelera el buscador del frontend (búsqueda insensible a mayúsculas).
CREATE INDEX idx_producto_nombre    ON producto (lower(nombre));

CREATE TRIGGER trg_producto_actualizado
    BEFORE UPDATE ON producto
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

COMMENT ON TABLE  producto              IS 'Productos del comercio, con precio e inventario.';
COMMENT ON COLUMN producto.sku          IS 'Código interno o código de barras. Único en todo el comercio.';
COMMENT ON COLUMN producto.precio_venta IS 'Precio SIN IVA, en pesos colombianos.';
COMMENT ON COLUMN producto.iva_pct      IS 'IVA por producto: 19 general, 5 reducido, 0 exento/excluido.';
COMMENT ON COLUMN producto.stock_minimo IS 'Umbral para la alerta de reposición.';


-- -----------------------------------------------------------------------------
-- cliente — destinatario de la factura
-- -----------------------------------------------------------------------------
CREATE TABLE cliente (
    id         SERIAL       PRIMARY KEY,
    tipo_doc   VARCHAR(5)   NOT NULL DEFAULT 'CC',
    num_doc    VARCHAR(20)  NOT NULL UNIQUE,
    nombre     VARCHAR(150) NOT NULL,
    email      VARCHAR(120),
    telefono   VARCHAR(30),
    direccion  VARCHAR(200),
    activo     BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT ck_cliente_tipo_doc CHECK (tipo_doc IN ('CC','NIT','CE','TI','PAS'))
);

CREATE INDEX idx_cliente_nombre ON cliente (lower(nombre));

COMMENT ON TABLE  cliente         IS 'Clientes del comercio. La fila id=1 es el consumidor final.';
COMMENT ON COLUMN cliente.num_doc IS 'Cédula o NIT. Único; valídenlo también con Pydantic.';


-- -----------------------------------------------------------------------------
-- venta — encabezado de la factura
-- -----------------------------------------------------------------------------
CREATE TABLE venta (
    id            SERIAL         PRIMARY KEY,
    numero        VARCHAR(20)    NOT NULL UNIQUE
                                 DEFAULT ('F-' || lpad(nextval('venta_numero_seq')::text, 6, '0')),
    cliente_id    INTEGER,
    fecha         TIMESTAMPTZ    NOT NULL DEFAULT now(),
    subtotal      NUMERIC(12,2)  NOT NULL DEFAULT 0,
    total_iva     NUMERIC(12,2)  NOT NULL DEFAULT 0,
    total         NUMERIC(12,2)  NOT NULL DEFAULT 0,
    metodo_pago   VARCHAR(20)    NOT NULL DEFAULT 'EFECTIVO',
    estado        VARCHAR(10)    NOT NULL DEFAULT 'PAGADA',
    observaciones TEXT,
    anulada_en    TIMESTAMPTZ,
    motivo_anula  VARCHAR(200),
    creado_en     TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (cliente_id) REFERENCES cliente (id)
        ON DELETE SET NULL,

    CONSTRAINT ck_venta_metodo   CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA','MIXTO')),
    CONSTRAINT ck_venta_estado   CHECK (estado      IN ('PAGADA','ANULADA')),
    CONSTRAINT ck_venta_subtotal CHECK (subtotal  >= 0),
    CONSTRAINT ck_venta_iva      CHECK (total_iva >= 0),
    CONSTRAINT ck_venta_total    CHECK (total     >= 0),
    -- Si está anulada, tiene que constar cuándo. Evita anulaciones "fantasma".
    CONSTRAINT ck_venta_anulacion CHECK (
        (estado = 'ANULADA' AND anulada_en IS NOT NULL) OR
        (estado = 'PAGADA'  AND anulada_en IS NULL)
    )
);

CREATE INDEX idx_venta_fecha   ON venta (fecha DESC);
CREATE INDEX idx_venta_estado  ON venta (estado);
CREATE INDEX idx_venta_cliente ON venta (cliente_id);

COMMENT ON TABLE  venta            IS 'Encabezado de venta. Nunca se borra físicamente: se anula.';
COMMENT ON COLUMN venta.numero     IS 'Consecutivo generado por la secuencia venta_numero_seq (F-000001).';
COMMENT ON COLUMN venta.cliente_id IS 'NULL = consumidor final sin identificar.';
COMMENT ON COLUMN venta.subtotal   IS 'Suma de líneas SIN IVA. Se calcula en el backend, jamás se recibe del frontend.';


-- -----------------------------------------------------------------------------
-- venta_item — líneas de la factura
-- -----------------------------------------------------------------------------
CREATE TABLE venta_item (
    id               SERIAL         PRIMARY KEY,
    venta_id         INTEGER        NOT NULL,
    producto_id      INTEGER        NOT NULL,
    cantidad         NUMERIC(10,3)  NOT NULL,
    precio_unitario  NUMERIC(12,2)  NOT NULL,
    iva_pct          NUMERIC(5,2)   NOT NULL,
    subtotal_linea   NUMERIC(12,2)  NOT NULL,
    iva_linea        NUMERIC(12,2)  NOT NULL,
    total_linea      NUMERIC(12,2)  NOT NULL,

    CONSTRAINT fk_item_venta
        FOREIGN KEY (venta_id) REFERENCES venta (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_item_producto
        FOREIGN KEY (producto_id) REFERENCES producto (id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_item_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_item_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT ck_item_iva      CHECK (iva_pct >= 0 AND iva_pct <= 100),
    -- Un mismo producto no se repite en la factura: se acumula la cantidad.
    CONSTRAINT uq_item_venta_producto UNIQUE (venta_id, producto_id)
);

CREATE INDEX idx_item_venta    ON venta_item (venta_id);
CREATE INDEX idx_item_producto ON venta_item (producto_id);

COMMENT ON TABLE  venta_item                 IS 'Detalle de la venta. Relación 1:N con venta.';
COMMENT ON COLUMN venta_item.precio_unitario IS 'COPIA CONGELADA del precio al momento de vender. Si el producto sube de precio mañana, esta factura no cambia.';
COMMENT ON COLUMN venta_item.iva_pct         IS 'También congelado: las tarifas de IVA cambian por ley.';


-- =============================================================================
-- BLOQUE 2 — EXTRAS  (kardex y usuarios)
--   Para recortar el alcance, borren desde aquí hasta el fin del bloque.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- usuario — quién opera la caja (habilita autenticación JWT y roles)
-- -----------------------------------------------------------------------------
CREATE TABLE usuario (
    id             SERIAL        PRIMARY KEY,
    email          VARCHAR(120)  NOT NULL UNIQUE,
    nombre         VARCHAR(120)  NOT NULL,
    password_hash  VARCHAR(255)  NOT NULL,
    rol            VARCHAR(10)   NOT NULL DEFAULT 'CAJERO',
    activo         BOOLEAN       NOT NULL DEFAULT TRUE,
    creado_en      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    ultimo_acceso  TIMESTAMPTZ,

    CONSTRAINT ck_usuario_rol CHECK (rol IN ('ADMIN','CAJERO'))
);

COMMENT ON TABLE  usuario               IS 'Operadores del POS. Autenticación con JWT.';
COMMENT ON COLUMN usuario.password_hash IS 'Hash bcrypt. Jamás texto plano, ni siquiera en seed.sql.';

-- La venta guarda quién la hizo. Se agrega por ALTER para que el BLOQUE 1
-- siga siendo autosuficiente si deciden no implementar autenticación.
ALTER TABLE venta ADD COLUMN usuario_id INTEGER;
ALTER TABLE venta ADD CONSTRAINT fk_venta_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL;
CREATE INDEX idx_venta_usuario ON venta (usuario_id);


-- -----------------------------------------------------------------------------
-- movimiento_inventario — kardex: por qué el stock es el que es
-- -----------------------------------------------------------------------------
CREATE TABLE movimiento_inventario (
    id                SERIAL         PRIMARY KEY,
    producto_id       INTEGER        NOT NULL,
    tipo              VARCHAR(12)    NOT NULL,
    cantidad          NUMERIC(10,3)  NOT NULL,
    stock_anterior    INTEGER        NOT NULL,
    stock_resultante  INTEGER        NOT NULL,
    venta_id          INTEGER,
    usuario_id        INTEGER,
    motivo            VARCHAR(200),
    fecha             TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_mov_producto
        FOREIGN KEY (producto_id) REFERENCES producto (id) ON DELETE RESTRICT,
    CONSTRAINT fk_mov_venta
        FOREIGN KEY (venta_id) REFERENCES venta (id) ON DELETE SET NULL,
    CONSTRAINT fk_mov_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL,

    CONSTRAINT ck_mov_tipo     CHECK (tipo IN ('ENTRADA','SALIDA','VENTA','ANULACION','AJUSTE','COMPRA')),
    CONSTRAINT ck_mov_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_mov_stock    CHECK (stock_resultante >= 0)
);

CREATE INDEX idx_mov_producto_fecha ON movimiento_inventario (producto_id, fecha DESC);
CREATE INDEX idx_mov_venta          ON movimiento_inventario (venta_id);

COMMENT ON TABLE  movimiento_inventario          IS 'Kardex. Cada cambio de stock deja rastro; permite auditar y reconstruir el inventario.';
COMMENT ON COLUMN movimiento_inventario.cantidad IS 'Siempre positiva. El signo lo determina la columna tipo.';


-- =============================================================================
-- BLOQUE 3 — OPCIONALES  (solo si sobra tiempo)
--   Borren el bloque completo si no los van a implementar.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- configuracion_comercio — datos del negocio (una sola fila)
-- -----------------------------------------------------------------------------
CREATE TABLE configuracion_comercio (
    id                SERIAL        PRIMARY KEY,
    razon_social      VARCHAR(150)  NOT NULL,
    nit               VARCHAR(20)   NOT NULL,
    direccion         VARCHAR(200),
    telefono          VARCHAR(30),
    prefijo_factura   VARCHAR(5)    NOT NULL DEFAULT 'F',
    resolucion_dian   VARCHAR(60),
    regimen           VARCHAR(30)   NOT NULL DEFAULT 'NO RESPONSABLE DE IVA',
    actualizado_en    TIMESTAMPTZ   NOT NULL DEFAULT now(),

    -- Una única fila posible: evita que la configuración se duplique.
    CONSTRAINT ck_config_fila_unica CHECK (id = 1)
);

COMMENT ON TABLE configuracion_comercio IS 'Datos del comercio para el encabezado del comprobante. Fila única (id=1).';


-- -----------------------------------------------------------------------------
-- proveedor / compra / compra_item — entradas de mercancía
-- -----------------------------------------------------------------------------
CREATE TABLE proveedor (
    id         SERIAL       PRIMARY KEY,
    nit        VARCHAR(20)  NOT NULL UNIQUE,
    nombre     VARCHAR(150) NOT NULL,
    contacto   VARCHAR(120),
    telefono   VARCHAR(30),
    email      VARCHAR(120),
    activo     BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE proveedor IS 'Proveedores de mercancía.';

CREATE TABLE compra (
    id             SERIAL         PRIMARY KEY,
    proveedor_id   INTEGER        NOT NULL,
    numero_factura VARCHAR(40)    NOT NULL,
    fecha          TIMESTAMPTZ    NOT NULL DEFAULT now(),
    subtotal       NUMERIC(12,2)  NOT NULL DEFAULT 0,
    total_iva      NUMERIC(12,2)  NOT NULL DEFAULT 0,
    total          NUMERIC(12,2)  NOT NULL DEFAULT 0,
    estado         VARCHAR(10)    NOT NULL DEFAULT 'RECIBIDA',
    creado_en      TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT fk_compra_proveedor
        FOREIGN KEY (proveedor_id) REFERENCES proveedor (id) ON DELETE RESTRICT,
    CONSTRAINT ck_compra_estado CHECK (estado IN ('RECIBIDA','ANULADA')),
    -- El mismo proveedor no puede facturarnos dos veces con el mismo número.
    CONSTRAINT uq_compra_proveedor_factura UNIQUE (proveedor_id, numero_factura)
);

CREATE INDEX idx_compra_fecha ON compra (fecha DESC);

CREATE TABLE compra_item (
    id              SERIAL         PRIMARY KEY,
    compra_id       INTEGER        NOT NULL,
    producto_id     INTEGER        NOT NULL,
    cantidad        NUMERIC(10,3)  NOT NULL,
    costo_unitario  NUMERIC(12,2)  NOT NULL,
    subtotal_linea  NUMERIC(12,2)  NOT NULL,

    CONSTRAINT fk_compra_item_compra
        FOREIGN KEY (compra_id) REFERENCES compra (id) ON DELETE CASCADE,
    CONSTRAINT fk_compra_item_producto
        FOREIGN KEY (producto_id) REFERENCES producto (id) ON DELETE RESTRICT,
    CONSTRAINT ck_compra_item_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_compra_item_costo    CHECK (costo_unitario >= 0)
);

CREATE INDEX idx_compra_item_compra ON compra_item (compra_id);

COMMENT ON TABLE compra_item IS 'Detalle de compra. Al registrarla, suma stock y genera movimiento tipo COMPRA.';


-- -----------------------------------------------------------------------------
-- caja_sesion — apertura, cierre y arqueo del turno
-- -----------------------------------------------------------------------------
CREATE TABLE caja_sesion (
    id              SERIAL         PRIMARY KEY,
    usuario_id      INTEGER,
    abierta_en      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    cerrada_en      TIMESTAMPTZ,
    base_inicial    NUMERIC(12,2)  NOT NULL DEFAULT 0,
    total_esperado  NUMERIC(12,2),
    total_contado   NUMERIC(12,2),
    diferencia      NUMERIC(12,2),
    estado          VARCHAR(10)    NOT NULL DEFAULT 'ABIERTA',
    observaciones   TEXT,

    CONSTRAINT fk_caja_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL,
    CONSTRAINT ck_caja_estado CHECK (estado IN ('ABIERTA','CERRADA')),
    CONSTRAINT ck_caja_base   CHECK (base_inicial >= 0)
);

-- Solo puede haber una caja abierta a la vez.
CREATE UNIQUE INDEX uq_caja_una_abierta
    ON caja_sesion (estado) WHERE estado = 'ABIERTA';

COMMENT ON TABLE caja_sesion            IS 'Turno de caja. diferencia = total_contado - total_esperado.';
COMMENT ON COLUMN caja_sesion.diferencia IS 'Negativa = faltante, positiva = sobrante.';

-- Enlaza cada venta con el turno en el que se hizo.
ALTER TABLE venta ADD COLUMN caja_sesion_id INTEGER;
ALTER TABLE venta ADD CONSTRAINT fk_venta_caja
    FOREIGN KEY (caja_sesion_id) REFERENCES caja_sesion (id) ON DELETE SET NULL;


-- =============================================================================
-- BLOQUE 4 — VISTAS DE APOYO
--   Le ahorran consultas al backend y quedan muy bien en la sustentación.
-- =============================================================================

-- Productos que hay que reponer.
CREATE OR REPLACE VIEW vw_productos_bajo_stock AS
SELECT p.id,
       p.sku,
       p.nombre,
       c.nombre AS categoria,
       p.stock_actual,
       p.stock_minimo,
       (p.stock_minimo - p.stock_actual) AS faltante
FROM producto p
JOIN categoria c ON c.id = p.categoria_id
WHERE p.activo = TRUE
  AND p.stock_actual <= p.stock_minimo
ORDER BY faltante DESC;

COMMENT ON VIEW vw_productos_bajo_stock IS 'Alerta de reposición: productos en o por debajo del stock mínimo.';

-- Ventas agrupadas por día (reporte del criterio de negocio).
CREATE OR REPLACE VIEW vw_ventas_por_dia AS
SELECT date_trunc('day', v.fecha)::date AS dia,
       count(*)                          AS num_ventas,
       sum(v.subtotal)                   AS subtotal,
       sum(v.total_iva)                  AS iva,
       sum(v.total)                      AS total
FROM venta v
WHERE v.estado = 'PAGADA'
GROUP BY 1
ORDER BY 1 DESC;

COMMENT ON VIEW vw_ventas_por_dia IS 'Resumen diario de ventas pagadas. Excluye las anuladas.';


-- =============================================================================
-- FIN DEL ESQUEMA
--   Siguiente paso: ejecutar seed.sql para cargar datos de prueba.
-- =============================================================================
