from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.producto import ProductoResumen
from app.schemas.proveedor import ProveedorResumen


class CompraItemCrear(BaseModel):
    producto_id: int
    # El stock de la base es entero, asi que las entradas tambien lo son.
    cantidad: int = Field(gt=0)
    costo_unitario: Decimal = Field(ge=0)


class CompraCrear(BaseModel):
    proveedor_id: int
    numero_factura: str = Field(min_length=1, max_length=40)
    costo_incluye_iva: bool = Field(
        default=False,
        description=(
            "true: el costo que facturo el proveedor ya trae IVA. Se guarda "
            "la base sin impuesto, porque el IVA de compra es descontable y "
            "no hace parte del valor del inventario."
        ),
    )
    items: list[CompraItemCrear] = Field(min_length=1)


class CompraAnular(BaseModel):
    motivo: str | None = Field(default=None, max_length=200)


class CompraItemLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    producto_id: int
    cantidad: Decimal
    costo_unitario: Decimal
    subtotal_linea: Decimal
    producto: ProductoResumen


class CompraLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    numero_factura: str
    fecha: datetime
    subtotal: Decimal
    total_iva: Decimal
    total: Decimal
    costo_incluye_iva: bool
    estado: str
    proveedor: ProveedorResumen
    items: list[CompraItemLeer]


class CompraListada(BaseModel):
    """Sin el detalle de items: es lo que se muestra en la tabla."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    numero_factura: str
    fecha: datetime
    subtotal: Decimal
    total_iva: Decimal
    total: Decimal
    costo_incluye_iva: bool
    estado: str
    proveedor: ProveedorResumen
