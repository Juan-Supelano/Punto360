import re
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

# Mismo formato que el CHECK de la base: 2 a 5 caracteres, solo A-Z y 0-9.
PATRON_PREFIJO = re.compile(r"^[A-Z0-9]{2,5}$")


def _normalizar_prefijo(valor: str | None) -> str | None:
    if valor is None:
        return None
    limpio = valor.strip().upper()
    if not PATRON_PREFIJO.match(limpio):
        raise ValueError(
            "El prefijo debe tener entre 2 y 5 caracteres, "
            "solo letras sin tilde y numeros (ejemplo: BEB, LACT)"
        )
    return limpio


class CategoriaCrear(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    descripcion: str | None = None
    prefijo_sku: str = Field(
        min_length=2,
        max_length=5,
        description="Prefijo para los SKU de esta categoria, por ejemplo BEB.",
    )

    @field_validator("prefijo_sku")
    @classmethod
    def validar_prefijo(cls, valor: str) -> str:
        return _normalizar_prefijo(valor)


class CategoriaActualizar(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=80)
    descripcion: str | None = None
    prefijo_sku: str | None = Field(default=None, min_length=2, max_length=5)
    activo: bool | None = None

    @field_validator("prefijo_sku")
    @classmethod
    def validar_prefijo(cls, valor: str | None) -> str | None:
        return _normalizar_prefijo(valor)


class CategoriaLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    descripcion: str | None
    prefijo_sku: str
    activo: bool
    creado_en: datetime


class CategoriaResumen(BaseModel):
    """Version corta, la que va anidada dentro de un producto."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    prefijo_sku: str
