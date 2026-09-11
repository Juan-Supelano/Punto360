from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.categoria import CategoriaResumen


class ProductoCrear(BaseModel):
    # El SKU no se manda: lo arma el backend con el prefijo de la categoria.
    nombre: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    precio_venta: Decimal = Field(ge=0)
    costo: Decimal = Field(default=Decimal("0"), ge=0)
    iva_pct: Decimal = Field(default=Decimal("19.00"), ge=0, le=100)
    stock_actual: int = Field(default=0, ge=0)
    stock_minimo: int = Field(default=0, ge=0)
    unidad_medida: str = Field(default="UND")
    categoria_id: int


class ProductoActualizar(BaseModel):
    # El SKU tampoco se edita: es un codigo derivado de la categoria.
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    descripcion: str | None = None
    precio_venta: Decimal | None = Field(default=None, ge=0)
    costo: Decimal | None = Field(default=None, ge=0)
    iva_pct: Decimal | None = Field(default=None, ge=0, le=100)
    stock_actual: int | None = Field(default=None, ge=0)
    stock_minimo: int | None = Field(default=None, ge=0)
    unidad_medida: str | None = None
    activo: bool | None = None
    categoria_id: int | None = None


class ProductoLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    nombre: str
    descripcion: str | None
    precio_venta: Decimal
    costo: Decimal
    iva_pct: Decimal
    stock_actual: int
    stock_minimo: int
    unidad_medida: str
    activo: bool
    creado_en: datetime
    actualizado_en: datetime
    categoria: CategoriaResumen
    # Calculados en el modelo, no son columnas.
    stock_bajo: bool
    margen_pct: Decimal | None


class ProductoResumen(BaseModel):
    """Version corta, la que va anidada dentro de una compra o una venta."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    nombre: str
    unidad_medida: str
