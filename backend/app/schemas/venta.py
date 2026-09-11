from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.venta import METODOS_PAGO
from app.schemas.cliente import ClienteResumen
from app.schemas.producto import ProductoResumen


class UsuarioResumen(BaseModel):
    """Quien atendio la venta."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    rol: str


class VentaItemCrear(BaseModel):
    producto_id: int
    # El stock de la base es entero, asi que las salidas tambien lo son.
    cantidad: int = Field(gt=0)


class VentaCrear(BaseModel):
    """El frontend manda producto y cantidad. Nada de precios:
    los pone el backend con lo que diga la base en ese momento."""

    cliente_id: int | None = None
    metodo_pago: str = Field(default="EFECTIVO")
    precio_incluye_iva: bool = Field(
        default=True,
        description=(
            "true: el precio del producto ya trae el IVA y la factura lo "
            "desglosa (1200 = 1008 base + 192 IVA). "
            "false: el precio es la base y el IVA se suma encima (1200 -> 1428)."
        ),
    )
    observaciones: str | None = None
    items: list[VentaItemCrear] = Field(min_length=1)

    @field_validator("metodo_pago")
    @classmethod
    def validar_metodo(cls, valor: str) -> str:
        limpio = valor.strip().upper()
        if limpio not in METODOS_PAGO:
            raise ValueError(
                f"Metodo de pago invalido. Use: {', '.join(METODOS_PAGO)}"
            )
        return limpio


class VentaAnular(BaseModel):
    motivo: str = Field(min_length=3, max_length=200)


class VentaItemLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    producto_id: int
    cantidad: Decimal
    precio_unitario: Decimal
    iva_pct: Decimal
    subtotal_linea: Decimal
    iva_linea: Decimal
    total_linea: Decimal
    producto: ProductoResumen


class VentaLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    numero: str
    fecha: datetime
    subtotal: Decimal
    total_iva: Decimal
    total: Decimal
    metodo_pago: str
    precio_incluye_iva: bool
    estado: str
    observaciones: str | None
    anulada_en: datetime | None
    motivo_anula: str | None
    cliente: ClienteResumen | None
    usuario: UsuarioResumen | None
    items: list[VentaItemLeer]


class VentaListada(BaseModel):
    """Sin el detalle de items: es lo que se muestra en la tabla."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    numero: str
    fecha: datetime
    subtotal: Decimal
    total_iva: Decimal
    total: Decimal
    metodo_pago: str
    precio_incluye_iva: bool
    estado: str
    cliente: ClienteResumen | None
    usuario: UsuarioResumen | None
