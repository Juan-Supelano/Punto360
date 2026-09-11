"""Esquemas Pydantic para gestion de usuarios (solo ADMIN)."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

RolUsuario = Literal["ADMIN", "CAJERO"]


class UsuarioCrear(BaseModel):
    email: EmailStr
    nombre: str = Field(min_length=1, max_length=120)
    password: str
    rol: RolUsuario

    @field_validator("password")
    @classmethod
    def password_minima(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("La contrasena debe tener al menos 8 caracteres")
        return v


class UsuarioActualizar(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    rol: RolUsuario | None = None
    activo: bool | None = None


class UsuarioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    nombre: str
    rol: str
    activo: bool
    creado_en: datetime
