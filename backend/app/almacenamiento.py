"""Guardado de archivos subidos por los usuarios (hoy: fotos de perfil).

Hoy todo vive en backend/static/, servido por FastAPI como archivos estaticos.
El dia que se migre a Cloud Storage, solo hay que cambiar la funcion
`guardar_foto_perfil` (subir el archivo al bucket y devolver su URL publica);
el resto de la app (modelo, schemas, router de perfil, frontend) sigue igual
porque solo conoce una URL en `usuario.foto_url`.
"""

import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

CARPETA_ESTATICOS = Path(__file__).resolve().parent.parent / "static"
CARPETA_FOTOS = CARPETA_ESTATICOS / "fotos"

EXTENSIONES_PERMITIDAS = {".jpg", ".jpeg", ".png", ".webp"}
TAMANO_MAXIMO_BYTES = 5 * 1024 * 1024  # 5 MB


def guardar_foto_perfil(usuario_id: int, archivo: UploadFile) -> str:
    """Valida y guarda la foto de perfil de `usuario_id`. Devuelve la URL
    publica (ruta relativa que el frontend arma junto con VITE_API_URL)."""
    extension = Path(archivo.filename or "").suffix.lower()
    if extension not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Formato no permitido. Usa JPG, PNG o WEBP.",
        )

    contenido = archivo.file.read()
    if len(contenido) > TAMANO_MAXIMO_BYTES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "La imagen no puede pesar mas de 5 MB"
        )

    CARPETA_FOTOS.mkdir(parents=True, exist_ok=True)
    nombre_archivo = f"usuario-{usuario_id}-{uuid.uuid4().hex}{extension}"
    destino = CARPETA_FOTOS / nombre_archivo
    destino.write_bytes(contenido)

    return f"/static/fotos/{nombre_archivo}"
