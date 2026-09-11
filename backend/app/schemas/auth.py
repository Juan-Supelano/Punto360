from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ComercioLeer(BaseModel):
    """Datos de la empresa que se muestran en la interfaz."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    razon_social: str
    nombre_comercial: str | None
    nombre_visible: str
    nit: str
    direccion: str | None
    ciudad: str | None
    telefono: str | None
    email: str | None
    logo_url: str | None


class ComercioActualizar(BaseModel):
    razon_social: str | None = Field(default=None, min_length=1, max_length=150)
    nombre_comercial: str | None = Field(default=None, max_length=150)
    nit: str | None = Field(default=None, min_length=1, max_length=20)
    direccion: str | None = Field(default=None, max_length=200)
    ciudad: str | None = Field(default=None, max_length=80)
    telefono: str | None = Field(default=None, max_length=30)
    email: str | None = Field(default=None, max_length=120)
    logo_url: str | None = Field(default=None, max_length=500)


class UsuarioLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    nombre: str
    rol: str
    activo: bool
    foto_url: str | None
    debe_cambiar_password: bool
    ultimo_acceso: datetime | None
    comercio: ComercioLeer


class LoginPeticion(BaseModel):
    email: str = Field(min_length=3, max_length=120)
    password: str = Field(min_length=1)

    @field_validator("email")
    @classmethod
    def normalizar_email(cls, valor: str) -> str:
        """Comprobacion minima de formato. Se evita depender de email-validator:
        el correo de verdad se valida contra la base al buscar el usuario."""
        limpio = valor.strip().lower()
        usuario, arroba, dominio = limpio.partition("@")
        if not arroba or not usuario or "." not in dominio:
            raise ValueError("El correo no tiene un formato valido")
        return limpio


class LoginRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expira_en: int  # segundos
    usuario: UsuarioLeer
