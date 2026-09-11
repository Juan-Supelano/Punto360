from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.producto import Producto
    from app.models.proveedor import Proveedor

# La base tiene un CHECK sobre compra.estado.
ESTADOS_COMPRA = ("RECIBIDA", "ANULADA")


class Compra(Base):
    __tablename__ = "compra"

    id: Mapped[int] = mapped_column(primary_key=True)
    proveedor_id: Mapped[int] = mapped_column(
        ForeignKey("proveedor.id"), nullable=False
    )
    numero_factura: Mapped[str] = mapped_column(String(40), nullable=False)
    fecha: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_iva: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    # true: el costo que facturo el proveedor ya traia IVA.
    costo_incluye_iva: Mapped[bool] = mapped_column(Boolean, nullable=False)
    estado: Mapped[str] = mapped_column(String(10), nullable=False)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    proveedor: Mapped["Proveedor"] = relationship(back_populates="compras")
    items: Mapped[list["CompraItem"]] = relationship(
        back_populates="compra", cascade="all, delete-orphan"
    )

    @property
    def anulada(self) -> bool:
        return self.estado == "ANULADA"


class CompraItem(Base):
    __tablename__ = "compra_item"

    id: Mapped[int] = mapped_column(primary_key=True)
    compra_id: Mapped[int] = mapped_column(ForeignKey("compra.id"), nullable=False)
    producto_id: Mapped[int] = mapped_column(
        ForeignKey("producto.id"), nullable=False
    )
    cantidad: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    costo_unitario: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    subtotal_linea: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    compra: Mapped["Compra"] = relationship(back_populates="items")
    producto: Mapped["Producto"] = relationship()
