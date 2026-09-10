from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.categoria import Categoria

# La base tiene un CHECK sobre esta columna: solo acepta estos valores.
UNIDADES = ("UND", "KG", "LT", "MT", "CAJA", "PAQ")


class Producto(Base):
    __tablename__ = "producto"

    id: Mapped[int] = mapped_column(primary_key=True)
    sku: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    nombre: Mapped[str] = mapped_column(String(150), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text)
    precio_venta: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    costo: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    iva_pct: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    stock_actual: Mapped[int] = mapped_column(Integer, nullable=False)
    stock_minimo: Mapped[int] = mapped_column(Integer, nullable=False)
    unidad_medida: Mapped[str] = mapped_column(String(15), nullable=False)
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    actualizado_en: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    categoria_id: Mapped[int] = mapped_column(
        ForeignKey("categoria.id"), nullable=False
    )
    categoria: Mapped["Categoria"] = relationship(back_populates="productos")

    @property
    def stock_bajo(self) -> bool:
        return self.stock_actual <= self.stock_minimo

    @property
    def margen_pct(self) -> Decimal | None:
        """Cuánto se gana sobre el costo. None si el costo es 0."""
        if not self.costo:
            return None
        return ((self.precio_venta - self.costo) / self.costo * 100).quantize(
            Decimal("0.01")
        )
