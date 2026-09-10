from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.usuario import Usuario


class Comercio(Base):
    """Datos de la empresa. La tabla tiene CHECK (id = 1): una sola fila."""

    __tablename__ = "configuracion_comercio"

    id: Mapped[int] = mapped_column(primary_key=True)
    razon_social: Mapped[str] = mapped_column(String(150), nullable=False)
    nombre_comercial: Mapped[str | None] = mapped_column(String(150))
    nit: Mapped[str] = mapped_column(String(20), nullable=False)
    direccion: Mapped[str | None] = mapped_column(String(200))
    ciudad: Mapped[str | None] = mapped_column(String(80))
    telefono: Mapped[str | None] = mapped_column(String(30))
    email: Mapped[str | None] = mapped_column(String(120))
    logo_url: Mapped[str | None] = mapped_column(String(500))
    prefijo_factura: Mapped[str] = mapped_column(String(5), nullable=False)
    resolucion_dian: Mapped[str | None] = mapped_column(String(60))
    regimen: Mapped[str] = mapped_column(String(30), nullable=False)
    actualizado_en: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    usuarios: Mapped[list["Usuario"]] = relationship(back_populates="comercio")

    @property
    def nombre_visible(self) -> str:
        return self.nombre_comercial or self.razon_social
