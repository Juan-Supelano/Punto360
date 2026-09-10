from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import Categoria, Producto  # noqa: F401  (registra las tablas)
from app.routers import categorias, productos


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Crea las tablas si no existen. Mas adelante esto lo reemplaza Alembic.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Cuadre POS API",
    description="API REST del punto de venta. Actividad integradora.",
    version="0.1.0",
    lifespan=lifespan,
)

# Permite que el frontend (otro puerto) pueda llamar a esta API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(categorias.router)
app.include_router(productos.router)


@app.get("/", tags=["Estado"])
def raiz():
    return {"servicio": "Cuadre POS API", "estado": "ok", "docs": "/docs"}


@app.get("/salud", tags=["Estado"])
def salud():
    return {"estado": "ok"}
