from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.categoria import CategoriaLeer


class ProductoCrear(BaseModel):
    codigo: str = Field(min_length=1, max_length=40)
    nombre: str = Field(min_length=1, max_length=120)
    precio_venta: Decimal = Field(gt=0, decimal_places=2)
    iva_porcentaje: Decimal = Field(default=Decimal("19.00"), ge=0, le=100)
    stock: int = Field(default=0, ge=0)
    categoria_id: int


class ProductoActualizar(BaseModel):
    codigo: str | None = Field(default=None, min_length=1, max_length=40)
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    precio_venta: Decimal | None = Field(default=None, gt=0)
    iva_porcentaje: Decimal | None = Field(default=None, ge=0, le=100)
    stock: int | None = Field(default=None, ge=0)
    categoria_id: int | None = None


class ProductoLeer(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    codigo: str
    nombre: str
    precio_venta: Decimal
    iva_porcentaje: Decimal
    stock: int
    activo: bool
    categoria: CategoriaLeer
