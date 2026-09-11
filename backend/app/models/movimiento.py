from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, func  # noqa: F401
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.producto import Producto

# La base tiene un CHECK sobre movimiento_inventario.tipo.
TIPOS_MOVIMIENTO = ("ENTRADA", "SALIDA", "VENTA", "ANULACION", "AJUSTE", "COMPRA")


class MovimientoInventario(Base):
    """Kardex: una fila por cada cambio de stock, con el antes y el despues."""

    __tablename__ = "movimiento_inventario"

    id: Mapped[int] = mapped_column(primary_key=True)
    producto_id: Mapped[int] = mapped_column(
        ForeignKey("producto.id"), nullable=False
    )
    tipo: Mapped[str] = mapped_column(String(12), nullable=False)
    cantidad: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    stock_anterior: Mapped[int] = mapped_column(Integer, nullable=False)
    stock_resultante: Mapped[int] = mapped_column(Integer, nullable=False)
    venta_id: Mapped[int | None] = mapped_column(ForeignKey("venta.id"))
    usuario_id: Mapped[int | None] = mapped_column(ForeignKey("usuario.id"))
    motivo: Mapped[str | None] = mapped_column(String(200))
    fecha: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    producto: Mapped["Producto"] = relationship()
