from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    DateTime,
    FetchedValue,
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
    from app.models.cliente import Cliente
    from app.models.producto import Producto
    from app.models.usuario import Usuario

# Las tres tienen CHECK en la base.
ESTADOS_VENTA = ("PAGADA", "ANULADA")
METODOS_PAGO = ("EFECTIVO", "TARJETA", "TRANSFERENCIA", "MIXTO")


class Venta(Base):
    __tablename__ = "venta"

    id: Mapped[int] = mapped_column(primary_key=True)
    # numero lo genera la base con su propia secuencia (F-000001, ...).
    # FetchedValue le dice a SQLAlchemy que no lo mande y lo lea de vuelta.
    numero: Mapped[str] = mapped_column(
        String(20), server_default=FetchedValue(), nullable=False
    )
    cliente_id: Mapped[int | None] = mapped_column(ForeignKey("cliente.id"))
    fecha: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_iva: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    metodo_pago: Mapped[str] = mapped_column(String(20), nullable=False)
    estado: Mapped[str] = mapped_column(String(10), nullable=False)
    observaciones: Mapped[str | None] = mapped_column(Text)
    anulada_en: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    motivo_anula: Mapped[str | None] = mapped_column(String(200))
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    usuario_id: Mapped[int | None] = mapped_column(ForeignKey("usuario.id"))
    # La caja todavia no se usa; queda en NULL hasta que se implemente.
    caja_sesion_id: Mapped[int | None] = mapped_column(Integer)

    cliente: Mapped["Cliente | None"] = relationship()
    usuario: Mapped["Usuario | None"] = relationship()
    items: Mapped[list["VentaItem"]] = relationship(
        back_populates="venta", cascade="all, delete-orphan"
    )

    @property
    def anulada(self) -> bool:
        return self.estado == "ANULADA"


class VentaItem(Base):
    """Los precios se CONGELAN aqui: si manana sube el precio del producto,
    esta venta sigue mostrando lo que se cobro ese dia."""

    __tablename__ = "venta_item"

    id: Mapped[int] = mapped_column(primary_key=True)
    venta_id: Mapped[int] = mapped_column(ForeignKey("venta.id"), nullable=False)
    producto_id: Mapped[int] = mapped_column(
        ForeignKey("producto.id"), nullable=False
    )
    cantidad: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    precio_unitario: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    iva_pct: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    subtotal_linea: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    iva_linea: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_linea: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    venta: Mapped["Venta"] = relationship(back_populates="items")
    producto: Mapped["Producto"] = relationship()
