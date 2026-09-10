from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.comercio import Comercio

ROLES = ("ADMIN", "CAJERO")


class Usuario(Base):
    __tablename__ = "usuario"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(10), nullable=False)
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    ultimo_acceso: Mapped[datetime | None] = mapped_column(DateTime)

    # Relación agregada por la migración 001: el usuario trabaja en esta empresa.
    comercio_id: Mapped[int] = mapped_column(
        ForeignKey("configuracion_comercio.id"), nullable=False
    )
    comercio: Mapped["Comercio"] = relationship(back_populates="usuarios")

    @property
    def es_admin(self) -> bool:
        return self.rol == "ADMIN"
