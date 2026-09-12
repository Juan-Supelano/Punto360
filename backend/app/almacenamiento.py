"""Carpeta de archivos estaticos servida por FastAPI (hoy: fotos de perfil
subidas antes de este cambio, que siguen viviendo en disco para no romper
enlaces ya guardados).

Las fotos nuevas (perfil y logo de empresa) se guardan como URL: el archivo
se sube a donde sea (por ejemplo Cloud Storage) y solo se pega su direccion
publica en `foto_url` / `logo_url`.
"""

from pathlib import Path

CARPETA_ESTATICOS = Path(__file__).resolve().parent.parent / "static"
CARPETA_FOTOS = CARPETA_ESTATICOS / "fotos"
