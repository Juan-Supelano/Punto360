from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CategoriaCrear(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    descripcion: str | None = None


class CategoriaActualizar(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=80)
    descripcion: str | None = None
    activo: bool | None = None


class CategoriaLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    descripcion: str | None
    activo: bool
    creado_en: datetime


class CategoriaResumen(BaseModel):
    """Versión corta, la que va anidada dentro de un producto."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
