from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.cliente import TIPOS_DOC


class ClienteCrear(BaseModel):
    tipo_doc: str = Field(default="CC", max_length=5)
    num_doc: str = Field(min_length=1, max_length=20)
    nombre: str = Field(min_length=1, max_length=150)
    email: str | None = Field(default=None, max_length=120)
    telefono: str | None = Field(default=None, max_length=30)
    direccion: str | None = Field(default=None, max_length=200)

    @field_validator("tipo_doc")
    @classmethod
    def validar_tipo(cls, valor: str) -> str:
        limpio = valor.strip().upper()
        if limpio not in TIPOS_DOC:
            raise ValueError(f"Tipo de documento invalido. Use: {', '.join(TIPOS_DOC)}")
        return limpio


class ClienteActualizar(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    email: str | None = Field(default=None, max_length=120)
    telefono: str | None = Field(default=None, max_length=30)
    direccion: str | None = Field(default=None, max_length=200)
    activo: bool | None = None


class ClienteLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tipo_doc: str
    num_doc: str
    nombre: str
    email: str | None
    telefono: str | None
    direccion: str | None
    activo: bool
    creado_en: datetime


class ClienteResumen(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tipo_doc: str
    num_doc: str
    nombre: str
