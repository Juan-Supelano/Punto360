from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import Categoria, Producto
from app.schemas.producto import ProductoActualizar, ProductoCrear, ProductoLeer

router = APIRouter(prefix="/productos", tags=["Productos"])


def _buscar(db: Session, producto_id: int) -> Producto:
    producto = db.get(Producto, producto_id)
    if producto is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Producto no encontrado")
    return producto


def _validar_categoria(db: Session, categoria_id: int) -> None:
    if db.get(Categoria, categoria_id) is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La categoria no existe")


@router.get("", response_model=list[ProductoLeer])
def listar(
    categoria_id: int | None = None,
    buscar: str | None = None,
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
        consulta = consulta.where(Producto.nombre.ilike(f"%{buscar}%"))
    return db.scalars(consulta).all()


@router.get("/{producto_id}", response_model=ProductoLeer)
def obtener(producto_id: int, db: Session = Depends(get_db)):
    return _buscar(db, producto_id)


@router.post("", response_model=ProductoLeer, status_code=status.HTTP_201_CREATED)
def crear(datos: ProductoCrear, db: Session = Depends(get_db)):
    _validar_categoria(db, datos.categoria_id)
    existe = db.scalar(select(Producto).where(Producto.codigo == datos.codigo))
    if existe is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe un producto con ese codigo")
    producto = Producto(**datos.model_dump())
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.put("/{producto_id}", response_model=ProductoLeer)
def actualizar(producto_id: int, datos: ProductoActualizar, db: Session = Depends(get_db)):
    producto = _buscar(db, producto_id)
    cambios = datos.model_dump(exclude_unset=True)
    if "categoria_id" in cambios:
        _validar_categoria(db, cambios["categoria_id"])
    for campo, valor in cambios.items():
        setattr(producto, campo, valor)
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
