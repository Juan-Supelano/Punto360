-- ============================================================================
-- Cuadre POS — migración 001: información de la empresa y su relación con usuario
--
-- Qué hace:
--   1. Agrega a configuracion_comercio los campos para mostrar la empresa
--      en la interfaz (nombre comercial, logo, ciudad, email).
--   2. Conecta usuario -> configuracion_comercio con una llave foránea,
--      para que cada usuario "trabaje en" una empresa.
--
-- Nota de diseño: configuracion_comercio tiene un CHECK (id = 1), así que hoy
-- solo puede existir una empresa y todos los usuarios apuntan a ella. La FK
-- deja el modelo bien conectado sin abrir multi-sucursal, que está declarado
-- fuera de alcance. Si algún día se quiere multi-empresa, se quita ese CHECK.
--
-- Ejecutar en pgAdmin sobre la base proyecto_nube. Es idempotente:
-- se puede correr dos veces sin romper nada.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Campos nuevos en configuracion_comercio
-- ----------------------------------------------------------------------------
ALTER TABLE configuracion_comercio
    ADD COLUMN IF NOT EXISTS nombre_comercial VARCHAR(150),
    ADD COLUMN IF NOT EXISTS logo_url         VARCHAR(500),
    ADD COLUMN IF NOT EXISTS email            VARCHAR(120),
    ADD COLUMN IF NOT EXISTS ciudad           VARCHAR(80);

COMMENT ON COLUMN configuracion_comercio.nombre_comercial IS
    'Nombre con el que se conoce el negocio. Si está vacío se muestra razon_social.';
COMMENT ON COLUMN configuracion_comercio.logo_url IS
    'URL pública del logo (bucket de Cloud Storage). La imagen NO se guarda en la base.';

-- ----------------------------------------------------------------------------
-- 2. Asegurar que exista la fila 1 (por el CHECK id = 1 solo puede haber una)
-- ----------------------------------------------------------------------------
INSERT INTO configuracion_comercio (id, razon_social, nit)
VALUES (1, 'Mi Comercio S.A.S.', '900000000-1')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. usuario.comercio_id -> configuracion_comercio.id
-- ----------------------------------------------------------------------------
ALTER TABLE usuario
    ADD COLUMN IF NOT EXISTS comercio_id INTEGER;

-- Los usuarios que ya existen quedan asociados a la empresa 1.
UPDATE usuario SET comercio_id = 1 WHERE comercio_id IS NULL;

ALTER TABLE usuario
    ALTER COLUMN comercio_id SET DEFAULT 1,
    ALTER COLUMN comercio_id SET NOT NULL;

-- ADD CONSTRAINT no admite IF NOT EXISTS, por eso el bloque condicional.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_usuario_comercio'
    ) THEN
        ALTER TABLE usuario
            ADD CONSTRAINT fk_usuario_comercio
            FOREIGN KEY (comercio_id)
            REFERENCES configuracion_comercio (id)
            ON DELETE RESTRICT;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usuario_comercio ON usuario (comercio_id);

COMMIT;

-- ============================================================================
-- Datos de ejemplo para ver algo en pantalla. Cambia los valores por los reales.
-- Se puede ejecutar aparte, no hace parte de la migración estructural.
-- ============================================================================
UPDATE configuracion_comercio
SET razon_social     = 'Comercializadora Cuadre S.A.S.',
    nombre_comercial = 'Cuadre POS',
    nit              = '901234567-8',
    direccion        = 'Calle 45 # 12-30',
    ciudad           = 'Bogotá D.C.',
    telefono         = '3001234567',
    email            = 'contacto@cuadrepos.co',
    logo_url         = 'https://storage.googleapis.com/cuadre-pos-publico/logo.png',
    actualizado_en   = now()
WHERE id = 1;

-- ----------------------------------------------------------------------------
-- Verificación
-- ----------------------------------------------------------------------------
-- SELECT id, razon_social, nombre_comercial, ciudad, logo_url
-- FROM configuracion_comercio;
--
-- SELECT u.id, u.email, u.nombre, u.rol, c.nombre_comercial
-- FROM usuario u JOIN configuracion_comercio c ON c.id = u.comercio_id;
