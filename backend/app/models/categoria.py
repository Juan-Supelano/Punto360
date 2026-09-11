from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.producto import Producto


class Categoria(Base):
    __tablename__ = "categoria"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text)
    # Con este prefijo el backend arma los SKU: BEB -> BEB-001, BEB-002...
    prefijo_sku: Mapped[str] = mapped_column(String(5), unique=True, nullable=False)
    # Nada se borra: se desactiva en vez de eliminar.
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    productos: Mapped[list["Producto"]] = relationship(back_populates="categoria")
