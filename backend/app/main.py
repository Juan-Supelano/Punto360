from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.almacenamiento import CARPETA_ESTATICOS, CARPETA_FOTOS
from app.config import settings
from app.models import (  # noqa: F401
    Categoria,
    Cliente,
    Comercio,
    Compra,
    CompraItem,
    MovimientoInventario,
    Producto,
    Proveedor,
    Usuario,
    Venta,
    VentaItem,
)
from app.routers import (
    auth,
    categorias,
    clientes,
    compras,
    perfil,
    productos,
    proveedores,
    usuarios,
    ventas,
)

# Debe existir antes de montar StaticFiles, aunque este vacia (por ejemplo en
# un contenedor recien construido que todavia no recibio ninguna foto).
CARPETA_FOTOS.mkdir(parents=True, exist_ok=True)

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

app.mount("/static", StaticFiles(directory=CARPETA_ESTATICOS), name="static")

app.include_router(auth.router)
app.include_router(categorias.router)
app.include_router(productos.router)
app.include_router(proveedores.router)
app.include_router(compras.router)
app.include_router(clientes.router)
app.include_router(ventas.router)
app.include_router(usuarios.router)
app.include_router(perfil.router)


@app.get("/", tags=["Estado"])
def raiz():
    return {"servicio": "Cuadre POS API", "estado": "ok", "docs": "/docs"}


@app.get("/salud", tags=["Estado"])
def salud():
    """Endpoint para el health check de Cloud Run."""
    return {"estado": "ok"}
