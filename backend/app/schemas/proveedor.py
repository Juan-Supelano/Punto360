from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ProveedorCrear(BaseModel):
    nit: str = Field(min_length=1, max_length=20)
    nombre: str = Field(min_length=1, max_length=150)
    contacto: str | None = Field(default=None, max_length=120)
    telefono: str | None = Field(default=None, max_length=30)
    email: str | None = Field(default=None, max_length=120)


class ProveedorActualizar(BaseModel):
    nit: str | None = Field(default=None, min_length=1, max_length=20)
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    contacto: str | None = Field(default=None, max_length=120)
    telefono: str | None = Field(default=None, max_length=30)
    email: str | None = Field(default=None, max_length=120)
    activo: bool | None = None


class ProveedorLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nit: str
    nombre: str
    contacto: str | None
    telefono: str | None
    email: str | None
    activo: bool
    creado_en: datetime


class ProveedorResumen(BaseModel):
    """Version corta, la que va anidada dentro de una compra."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nit: str
    nombre: str
