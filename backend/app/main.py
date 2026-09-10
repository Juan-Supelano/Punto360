from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.models import Categoria, Comercio, Producto, Usuario  # noqa: F401
from app.routers import auth, categorias, productos

# Ojo: aqui NO se llama Base.metadata.create_all().
# El esquema de proyecto_nube lo administra el script SQL del equipo (y mas
# adelante Alembic). Si el codigo tambien creara tablas, terminarian existiendo
# dos versiones distintas del mismo modelo y los errores serian silenciosos.

app = FastAPI(
    title="Cuadre POS API",
    description=(
        "API REST del punto de venta. Actividad integradora.\n\n"
        "Casi todos los endpoints piden token: primero llama a "
        "`POST /auth/login` y pega el `access_token` en el boton **Authorize**."
    ),
    version="0.2.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.lista_cors,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(categorias.router)
app.include_router(productos.router)


@app.get("/", tags=["Estado"])
def raiz():
    return {"servicio": "Cuadre POS API", "estado": "ok", "docs": "/docs"}


@app.get("/salud", tags=["Estado"])
def salud():
    """Endpoint para el health check de Cloud Run."""
    return {"estado": "ok"}
