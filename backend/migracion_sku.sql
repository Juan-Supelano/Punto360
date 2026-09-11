-- ============================================================================
-- Cuadre POS — migración 002: prefijo de SKU por categoría
--
-- El prefijo lo decide el ADMINISTRADOR, no la base ni el backend. Por eso
-- esta migración va en tres pasos y el paso 2 lo escribes tú a mano.
--
-- A partir de aquí el backend arma los SKU solo: PREFIJO-001, PREFIJO-002...
-- pero el prefijo siempre sale de lo que el admin haya digitado.
--
-- Ejecutar en pgAdmin sobre la base proyecto_nube.
-- ============================================================================


-- ############################################################################
-- PASO 0 — mira qué categorías tienes (ejecuta solo esta línea primero)
-- ############################################################################

SELECT id, nombre FROM categoria ORDER BY nombre;


-- ############################################################################
-- PASO 1 — crear la columna, todavía aceptando nulos
-- ############################################################################

ALTER TABLE categoria
    ADD COLUMN IF NOT EXISTS prefijo_sku VARCHAR(5);

COMMENT ON COLUMN categoria.prefijo_sku IS
    'Prefijo que digita el administrador. El backend genera BEB-001, BEB-002...';


-- ############################################################################
-- PASO 2 — ESCRIBE AQUÍ LOS PREFIJOS
--
-- Reemplaza esta lista con los nombres que te salieron en el PASO 0 y el
-- prefijo que quieras para cada uno. Reglas: 2 a 5 caracteres, solo letras
-- sin tilde y números, en mayúscula, y ninguno repetido.
--
-- Los de abajo son un EJEMPLO. Bórralos y pon los tuyos.
-- ############################################################################

UPDATE categoria c
SET prefijo_sku = v.prefijo
FROM (VALUES
    ('Bebidas',   'BEB'),
    ('Panadería', 'PAN'),
    ('Aseo',      'ASE'),
    ('Lácteos',   'LAC'),
    ('Snacks',    'SNK')
) AS v(nombre, prefijo)
WHERE c.nombre = v.nombre;

-- Si prefieres ir una por una con el id que viste en el PASO 0:
-- UPDATE categoria SET prefijo_sku = 'BEB' WHERE id = 1;


-- ############################################################################
-- PASO 3 — cerrar las reglas
--
-- Si alguna categoría quedó sin prefijo, esto se detiene con un mensaje que
-- dice cuál falta. Vuelve al PASO 2, complétala y ejecuta de nuevo.
-- ############################################################################

DO $$
DECLARE
    faltantes text;
    repetidos text;
BEGIN
    SELECT string_agg(nombre, ', ' ORDER BY nombre) INTO faltantes
    FROM categoria WHERE prefijo_sku IS NULL;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'Faltan prefijos por digitar en estas categorias: %. Completa el PASO 2.',
            faltantes;
    END IF;

    SELECT string_agg(prefijo_sku, ', ') INTO repetidos
    FROM (
        SELECT prefijo_sku FROM categoria
        GROUP BY prefijo_sku HAVING count(*) > 1
    ) AS d;

    IF repetidos IS NOT NULL THEN
        RAISE EXCEPTION
            'Estos prefijos estan repetidos: %. Cada categoria necesita uno distinto.',
            repetidos;
    END IF;
END $$;

ALTER TABLE categoria
    ALTER COLUMN prefijo_sku SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_categoria_prefijo_sku'
    ) THEN
        ALTER TABLE categoria
            ADD CONSTRAINT uq_categoria_prefijo_sku UNIQUE (prefijo_sku);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'ck_categoria_prefijo_sku'
    ) THEN
        ALTER TABLE categoria
            ADD CONSTRAINT ck_categoria_prefijo_sku
            CHECK (prefijo_sku ~ '^[A-Z0-9]{2,5}$');
    END IF;
END $$;


-- ############################################################################
-- Verificación
-- ############################################################################

SELECT id, nombre, prefijo_sku FROM categoria ORDER BY nombre;

-- De aquí en adelante los prefijos se cambian desde la pantalla de Categorías
-- del POS, con un usuario ADMIN. No hace falta volver a tocar SQL.


-- ############################################################################
-- OPCIONAL — renumerar los SKU de los productos que YA existen
--
-- NO se ejecuta solo, y con razón: si ya imprimieron etiquetas, pegaron
-- códigos en los estantes o los proveedores usan esos SKU, renumerar los
-- rompe todos. Los SKU viejos siguen funcionando tal como están; el prefijo
-- solo afecta a los productos NUEVOS.
--
-- Si aun así quieren dejar el catálogo uniforme, descomenten y ejecuten una
-- sola vez.
-- ############################################################################
-- BEGIN;
--
-- WITH nuevo AS (
--     SELECT
--         p.id,
--         c.prefijo_sku || '-' ||
--         lpad(row_number() OVER (PARTITION BY p.categoria_id
--                                 ORDER BY p.nombre)::text, 3, '0') AS sku_nuevo
--     FROM producto p
--     JOIN categoria c ON c.id = p.categoria_id
-- )
-- UPDATE producto p
-- SET sku = n.sku_nuevo,
--     actualizado_en = now()
-- FROM nuevo n
-- WHERE p.id = n.id
--   AND p.sku <> n.sku_nuevo;
--
-- COMMIT;
