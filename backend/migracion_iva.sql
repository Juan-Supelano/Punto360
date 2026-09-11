-- ============================================================================
-- Cuadre POS — migración 003: IVA incluido o agregado
--
-- Hasta ahora el sistema asumía que el precio del producto era la BASE y que
-- al IVA se le sumaba encima. En un mostrador colombiano suele ser al revés:
-- el precio de góndola ya trae el impuesto, y la factura tiene que
-- descomponerlo, no encarecerlo.
--
--   Bolígrafo 1.200 con IVA 19% incluido:
--       Subtotal   1.008,40
--       IVA 19%      191,60
--       TOTAL      1.200,00
--
-- La marca va por documento: una casilla al cobrar (venta) y otra al registrar
-- la compra. Se guarda en el documento y no se recalcula nunca, para que una
-- factura vieja siga mostrando lo mismo que se imprimió ese día.
--
-- Ejecutar en pgAdmin sobre proyecto_nube. Es idempotente.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Ventas
-- ----------------------------------------------------------------------------
ALTER TABLE venta
    ADD COLUMN IF NOT EXISTS precio_incluye_iva boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN venta.precio_incluye_iva IS
    'true: precio_unitario de cada linea ya trae el IVA y la factura lo desglosa. '
    'false: precio_unitario es la base y el IVA se suma encima.';

-- ----------------------------------------------------------------------------
-- Compras
-- ----------------------------------------------------------------------------
ALTER TABLE compra
    ADD COLUMN IF NOT EXISTS costo_incluye_iva boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN compra.costo_incluye_iva IS
    'true: el costo que facturo el proveedor ya trae IVA. En ese caso '
    'compra_item.subtotal_linea guarda la base sin impuesto, y producto.costo '
    'tambien, porque el IVA de compra es descontable y no hace parte del '
    'valor del inventario.';

COMMIT;

-- ============================================================================
-- Por qué los documentos viejos quedan como quedan
--
-- venta.precio_incluye_iva arranca en TRUE y compra.costo_incluye_iva en FALSE.
-- Eso NO es un descuido: es lo que ya estaba pasando. Las ventas anteriores se
-- calcularon sumando el IVA sobre el precio... pero el cliente pagaba el total
-- que mostraba la pantalla. Si les pusieras FALSE, sus cifras guardadas
-- seguirían siendo las mismas (nada se recalcula), así que el valor de la
-- columna solo importa de aquí en adelante.
--
-- Si quieren que los datos de prueba viejos se vean coherentes con el modo
-- nuevo, lo más limpio es borrarlos y volver a facturar, no reescribir los
-- totales de documentos ya emitidos.
-- ============================================================================

-- Verificación
SELECT 'venta' AS tabla, precio_incluye_iva AS incluye_iva, count(*)
FROM venta GROUP BY 1, 2
UNION ALL
SELECT 'compra', costo_incluye_iva, count(*)
FROM compra GROUP BY 1, 2;
