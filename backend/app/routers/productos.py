from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import Categoria, Producto, Usuario
from app.models.producto import UNIDADES
from app.schemas.producto import ProductoActualizar, ProductoCrear, ProductoLeer
from app.seguridad import usuario_actual

router = APIRouter(
    prefix="/productos",
    tags=["Productos"],
    dependencies=[Depends(usuario_actual)],
)


def _buscar(db: Session, producto_id: int) -> Producto:
    producto = db.get(Producto, producto_id)
    if producto is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Producto no encontrado")
    return producto


def _validar_categoria(db: Session, categoria_id: int) -> None:
    categoria = db.get(Categoria, categoria_id)
    if categoria is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La categoria no existe")
    if not categoria.activo:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "La categoria esta desactivada"
        )


def _validar_unidad(unidad: str | None) -> None:
    if unidad is not None and unidad not in UNIDADES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Unidad de medida invalida. Use una de: {', '.join(UNIDADES)}",
        )


@router.get("", response_model=list[ProductoLeer])
def listar(
    categoria_id: int | None = None,
    buscar: str | None = None,
    solo_stock_bajo: bool = False,
    incluir_inactivos: bool = False,
    db: Session = Depends(get_db),
):
    consulta = (
        select(Producto)
        .options(selectinload(Producto.categoria))
        .order_by(Producto.nombre)
    )
    if not incluir_inactivos:
        consulta = consulta.where(Producto.activo.is_(True))
    if categoria_id is not None:
        consulta = consulta.where(Producto.categoria_id == categoria_id)
    if buscar:
        patron = f"%{buscar}%"
        consulta = consulta.where(
            or_(Producto.nombre.ilike(patron), Producto.sku.ilike(patron))
        )
    if solo_stock_bajo:
        consulta = consulta.where(Producto.stock_actual <= Producto.stock_minimo)
    return db.scalars(consulta).all()


@router.get("/{producto_id}", response_model=ProductoLeer)
def obtener(producto_id: int, db: Session = Depends(get_db)):
    return _buscar(db, producto_id)


@router.post("", response_model=ProductoLeer, status_code=status.HTTP_201_CREATED)
def crear(datos: ProductoCrear, db: Session = Depends(get_db)):
    _validar_categoria(db, datos.categoria_id)
    _validar_unidad(datos.unidad_medida)

    sku = datos.sku.strip().upper()
    if db.scalar(select(Producto).where(Producto.sku == sku)) is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, f"Ya existe un producto con el SKU {sku}"
        )

    producto = Producto(**{**datos.model_dump(), "sku": sku, "activo": True})
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.put("/{producto_id}", response_model=ProductoLeer)
def actualizar(
    producto_id: int, datos: ProductoActualizar, db: Session = Depends(get_db)
):
    producto = _buscar(db, producto_id)
    cambios = datos.model_dump(exclude_unset=True)

    if "categoria_id" in cambios:
        _validar_categoria(db, cambios["categoria_id"])
    if "unidad_medida" in cambios:
        _validar_unidad(cambios["unidad_medida"])
    if "sku" in cambios:
        cambios["sku"] = cambios["sku"].strip().upper()
        repetido = db.scalar(
            select(Producto).where(
                Producto.sku == cambios["sku"], Producto.id != producto_id
            )
        )
        if repetido is not None:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"Ya existe otro producto con el SKU {cambios['sku']}",
            )

    for campo, valor in cambios.items():
        setattr(producto, campo, valor)

    db.commit()
    db.refresh(producto)
    return producto


@router.patch("/{producto_id}/stock", response_model=ProductoLeer)
def ajustar_stock(
    producto_id: int,
    cantidad: int = Query(
        description="Positivo suma unidades, negativo las resta."
    ),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(usuario_actual),
):
    """Ajuste manual de inventario. El kardex se conectara aqui mas adelante."""
    producto = _buscar(db, producto_id)
    nuevo = producto.stock_actual + cantidad
    if nuevo < 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"No hay stock suficiente. Disponible: {producto.stock_actual}",
        )
    producto.stock_actual = nuevo
    db.commit()
    db.refresh(producto)
    return producto


@router.delete("/{producto_id}", response_model=ProductoLeer)
def desactivar(producto_id: int, db: Session = Depends(get_db)):
    """No borra el registro: lo marca como inactivo."""
    producto = _buscar(db, producto_id)
    producto.activo = False
    db.commit()
    db.refresh(producto)
    return producto


@router.post("/{producto_id}/reactivar", response_model=ProductoLeer)
def reactivar(producto_id: int, db: Session = Depends(get_db)):
    producto = _buscar(db, producto_id)
    producto.activo = True
    db.commit()
    db.refresh(producto)
    return producto
