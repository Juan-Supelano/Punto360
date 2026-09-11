-- ============================================================================
-- Cuadre POS — migración 003: perfil de usuario (foto y contraseña temporal)
--
-- Qué hace:
--   1. Agrega a usuario el campo foto_url (URL/ruta pública de la foto de
--      perfil, guardada hoy en backend/static/fotos/).
--   2. Agrega usuario.debe_cambiar_password: cuando un ADMIN crea un usuario
--      o le resetea la contraseña, esta bandera queda en true y el frontend
--      obliga a cambiarla antes de dejar entrar a cualquier otra pantalla.
--      Reemplaza cualquier flujo de "olvidé mi contraseña" por correo (los
--      correos de los usuarios son ficticios).
--
-- Ejecutar en pgAdmin sobre la base configurada en DATABASE_URL. Es
-- idempotente: se puede correr dos veces sin romper nada.
-- ============================================================================

BEGIN;

ALTER TABLE usuario
    ADD COLUMN IF NOT EXISTS foto_url              TEXT,
    ADD COLUMN IF NOT EXISTS debe_cambiar_password  BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN usuario.foto_url IS
    'URL o ruta publica de la foto de perfil. Hoy vive en backend/static/fotos/, listo para migrar a Cloud Storage.';
COMMENT ON COLUMN usuario.debe_cambiar_password IS
    'true = la contrasena es temporal (recien creada o reseteada por un ADMIN) y el frontend obliga a cambiarla antes de usar el resto de la app.';

COMMIT;

-- ----------------------------------------------------------------------------
-- Verificación
-- ----------------------------------------------------------------------------
-- SELECT id, email, nombre, foto_url, debe_cambiar_password FROM usuario;
