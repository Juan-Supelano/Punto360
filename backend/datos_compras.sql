-- ============================================================================
-- Cuadre POS — datos de ejemplo para el módulo de compras
--
-- Crea 6 compras repartidas entre los proveedores que ya existen, con sus
-- líneas, y hace lo mismo que haría el backend:
--   - suma el stock de cada producto comprado
--   - actualiza producto.costo con el último costo de compra
--   - escribe una fila en movimiento_inventario (kardex) por cada entrada
-- La última queda ANULADA, con su reversa de stock, para que puedas ver ese
-- caso en pantalla.
--
-- No inventa proveedores ni productos: usa los que ya están cargados y les
-- calcula los totales, así que sirve sin importar qué ids tengas.
--
-- Ejecutar completo en pgAdmin sobre proyecto_nube. Si lo corres dos veces
-- avisa y no hace nada, para no inflar el inventario por accidente.
-- ============================================================================

BEGIN;

DO $$
DECLARE
    v_admin       integer;
    v_proveedores integer[];
    v_n_prov      integer;
    v_n_prod      integer;
    c             record;
    p             record;
    v_compra_id   integer;
    v_prov_id     integer;
    v_fecha       timestamptz;
    v_subtotal    numeric(12,2);
    v_iva         numeric(12,2);
    v_cantidad    integer;
    v_costo       numeric(12,2);
    v_sub_linea   numeric(12,2);
    v_anterior    integer;
    v_items       integer;
BEGIN
    ------------------------------------------------------------------
    -- Guardas
    ------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM compra WHERE numero_factura LIKE 'FV-10%') THEN
        RAISE NOTICE 'Los datos de ejemplo ya estaban cargados. No se hizo nada.';
        RETURN;
    END IF;

    SELECT id INTO v_admin
    FROM usuario WHERE rol = 'ADMIN' AND activo ORDER BY id LIMIT 1;

    IF v_admin IS NULL THEN
        RAISE EXCEPTION 'No hay ningun usuario con rol ADMIN activo.';
    END IF;

    SELECT array_agg(id ORDER BY id) INTO v_proveedores
    FROM proveedor WHERE activo;

    v_n_prov := coalesce(array_length(v_proveedores, 1), 0);
    IF v_n_prov = 0 THEN
        RAISE EXCEPTION 'No hay proveedores activos. Crea al menos uno primero.';
    END IF;

    SELECT count(*) INTO v_n_prod FROM producto WHERE activo;
    IF v_n_prod < 4 THEN
        RAISE EXCEPTION 'Se necesitan al menos 4 productos activos. Hay %.', v_n_prod;
    END IF;

    ------------------------------------------------------------------
    -- Las compras a crear
    --   prov_pos : posicion del proveedor (rota si hay menos de 3)
    --   dias     : hace cuantos dias ocurrio
    --   n_items  : cuantos productos lleva
    --   salto    : desde que producto empieza a tomar (para no repetir)
    ------------------------------------------------------------------
    FOR c IN
        SELECT * FROM (VALUES
            (1, 'FV-1001', 52, 4,  0, 'RECIBIDA'),
            (2, 'FV-1002', 41, 3,  4, 'RECIBIDA'),
            (3, 'FV-1003', 33, 4,  7, 'RECIBIDA'),
            (1, 'FV-1004', 18, 3, 11, 'RECIBIDA'),
            (2, 'FV-1005',  9, 4, 14, 'RECIBIDA'),
            (3, 'FV-1006',  4, 3, 18, 'ANULADA')
        ) AS t(prov_pos, factura, dias, n_items, salto, estado)
    LOOP
        v_prov_id := v_proveedores[((c.prov_pos - 1) % v_n_prov) + 1];
        v_fecha   := now() - (c.dias || ' days')::interval;

        INSERT INTO compra (proveedor_id, numero_factura, fecha,
                            subtotal, total_iva, total, estado)
        VALUES (v_prov_id, c.factura, v_fecha, 0, 0, 0, 'RECIBIDA')
        RETURNING id INTO v_compra_id;

        v_subtotal := 0;
        v_iva      := 0;
        v_items    := 0;

        --------------------------------------------------------------
        -- Lineas de la compra: entrada de stock + kardex
        --------------------------------------------------------------
        FOR p IN
            SELECT id, costo, precio_venta, iva_pct, stock_actual
            FROM producto
            WHERE activo
            ORDER BY id
            OFFSET (c.salto % GREATEST(v_n_prod - c.n_items, 1))
            LIMIT c.n_items
        LOOP
            -- Cantidad "aleatoria" pero estable: entre 5 y 20 unidades.
            v_cantidad := 5 + (p.id % 16);

            -- Si el producto no tiene costo, se estima en el 62% del precio.
            v_costo := CASE
                WHEN p.costo > 0 THEN p.costo
                ELSE round(p.precio_venta * 0.62, 2)
            END;

            v_sub_linea := round(v_costo * v_cantidad, 2);

            INSERT INTO compra_item (compra_id, producto_id, cantidad,
                                     costo_unitario, subtotal_linea)
            VALUES (v_compra_id, p.id, v_cantidad, v_costo, v_sub_linea);

            v_anterior := p.stock_actual;

            UPDATE producto
               SET stock_actual   = stock_actual + v_cantidad,
                   costo          = v_costo,
                   actualizado_en = now()
             WHERE id = p.id;

            INSERT INTO movimiento_inventario (
                producto_id, tipo, cantidad,
                stock_anterior, stock_resultante,
                usuario_id, motivo, fecha
            )
            VALUES (
                p.id, 'COMPRA', v_cantidad,
                v_anterior, v_anterior + v_cantidad,
                v_admin, 'Compra ' || c.factura || ' (datos de ejemplo)', v_fecha
            );

            v_subtotal := v_subtotal + v_sub_linea;
            v_iva      := v_iva + round(v_sub_linea * p.iva_pct / 100, 2);
            v_items    := v_items + 1;
        END LOOP;

        IF v_items = 0 THEN
            RAISE EXCEPTION 'La compra % quedo sin lineas. Revisa cuantos productos activos hay.',
                c.factura;
        END IF;

        UPDATE compra
           SET subtotal  = v_subtotal,
               total_iva = v_iva,
               total     = v_subtotal + v_iva
         WHERE id = v_compra_id;

        --------------------------------------------------------------
        -- Caso anulado: se devuelve el stock y queda el rastro
        --------------------------------------------------------------
        IF c.estado = 'ANULADA' THEN
            FOR p IN
                SELECT ci.producto_id AS id,
                       ci.cantidad::integer AS cantidad,
                       pr.stock_actual
                FROM compra_item ci
                JOIN producto pr ON pr.id = ci.producto_id
                WHERE ci.compra_id = v_compra_id
            LOOP
                UPDATE producto
                   SET stock_actual   = stock_actual - p.cantidad,
                       actualizado_en = now()
                 WHERE id = p.id;

                INSERT INTO movimiento_inventario (
                    producto_id, tipo, cantidad,
                    stock_anterior, stock_resultante,
                    usuario_id, motivo, fecha
                )
                VALUES (
                    p.id, 'ANULACION', p.cantidad,
                    p.stock_actual, p.stock_actual - p.cantidad,
                    v_admin,
                    'Anulacion compra ' || c.factura || ': factura duplicada del proveedor',
                    v_fecha + interval '2 hours'
                );
            END LOOP;

            UPDATE compra SET estado = 'ANULADA' WHERE id = v_compra_id;
        END IF;

        RAISE NOTICE 'Compra % creada con % lineas, total %',
            c.factura, v_items, v_subtotal + v_iva;
    END LOOP;

    RAISE NOTICE 'Listo: 6 compras de ejemplo cargadas.';
END $$;

COMMIT;


-- ============================================================================
-- Verificación
-- ============================================================================

-- Las compras con su proveedor
SELECT c.numero_factura,
       p.nombre AS proveedor,
       c.fecha::date,
       c.subtotal,
       c.total_iva,
       c.total,
       c.estado,
       count(ci.id) AS lineas
FROM compra c
JOIN proveedor p   ON p.id = c.proveedor_id
LEFT JOIN compra_item ci ON ci.compra_id = c.id
GROUP BY c.id, p.nombre
ORDER BY c.fecha DESC;

-- El kardex que quedó
SELECT m.fecha::date, pr.sku, pr.nombre, m.tipo,
       m.cantidad, m.stock_anterior, m.stock_resultante, m.motivo
FROM movimiento_inventario m
JOIN producto pr ON pr.id = m.producto_id
ORDER BY m.fecha DESC, m.id DESC
LIMIT 40;

-- Comprobación de cuadre: el stock de cada producto debe coincidir con el
-- último stock_resultante que registró el kardex.
SELECT pr.sku, pr.nombre, pr.stock_actual, ultimo.stock_resultante
FROM producto pr
JOIN LATERAL (
    SELECT stock_resultante
    FROM movimiento_inventario m
    WHERE m.producto_id = pr.id
    ORDER BY m.fecha DESC, m.id DESC
    LIMIT 1
) AS ultimo ON true
WHERE pr.stock_actual <> ultimo.stock_resultante;
-- Si esta última consulta devuelve 0 filas, el inventario y el kardex cuadran.


-- ============================================================================
-- DESHACER — borra las compras de ejemplo y devuelve el stock
-- Descomentar y ejecutar solo si quieres dejar la base como estaba.
-- ============================================================================
-- BEGIN;
--
-- -- Devuelve el stock de las compras RECIBIDAS de ejemplo
-- -- (las ANULADAS ya lo habían devuelto).
-- UPDATE producto pr
-- SET stock_actual = pr.stock_actual - x.entrada
-- FROM (
--     SELECT ci.producto_id, sum(ci.cantidad)::integer AS entrada
--     FROM compra_item ci
--     JOIN compra c ON c.id = ci.compra_id
--     WHERE c.numero_factura LIKE 'FV-10%' AND c.estado = 'RECIBIDA'
--     GROUP BY ci.producto_id
-- ) AS x
-- WHERE pr.id = x.producto_id;
--
-- DELETE FROM movimiento_inventario WHERE motivo LIKE '%FV-10%';
-- DELETE FROM compra_item WHERE compra_id IN (
--     SELECT id FROM compra WHERE numero_factura LIKE 'FV-10%'
-- );
-- DELETE FROM compra WHERE numero_factura LIKE 'FV-10%';
--
-- COMMIT;
