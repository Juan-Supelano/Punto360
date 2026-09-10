from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Categoria, Producto
from app.schemas.categoria import CategoriaActualizar, CategoriaCrear, CategoriaLeer
from app.seguridad import usuario_actual

router = APIRouter(
    prefix="/categorias",
    tags=["Categorias"],
    dependencies=[Depends(usuario_actual)],
)


def _buscar(db: Session, categoria_id: int) -> Categoria:
    categoria = db.get(Categoria, categoria_id)
    if categoria is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Categoria no encontrada")
    return categoria


@router.get("", response_model=list[CategoriaLeer])
def listar(incluir_inactivas: bool = False, db: Session = Depends(get_db)):
    consulta = select(Categoria).order_by(Categoria.nombre)
    if not incluir_inactivas:
        consulta = consulta.where(Categoria.activo.is_(True))
    return db.scalars(consulta).all()


@router.get("/{categoria_id}", response_model=CategoriaLeer)
def obtener(categoria_id: int, db: Session = Depends(get_db)):
    return _buscar(db, categoria_id)


@router.post("", response_model=CategoriaLeer, status_code=status.HTTP_201_CREATED)
def crear(datos: CategoriaCrear, db: Session = Depends(get_db)):
    nombre = datos.nombre.strip()
    repetida = db.scalar(
        select(Categoria).where(func.lower(Categoria.nombre) == nombre.lower())
    )
    if repetida is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Ya existe una categoria con ese nombre"
        )

    categoria = Categoria(
        nombre=nombre, descripcion=datos.descripcion, activo=True
    )
    db.add(categoria)
    db.commit()
    db.refresh(categoria)
    return categoria


@router.put("/{categoria_id}", response_model=CategoriaLeer)
def actualizar(
    categoria_id: int, datos: CategoriaActualizar, db: Session = Depends(get_db)
):
    categoria = _buscar(db, categoria_id)
    cambios = datos.model_dump(exclude_unset=True)

    if "nombre" in cambios:
        cambios["nombre"] = cambios["nombre"].strip()
        repetida = db.scalar(
            select(Categoria).where(
                func.lower(Categoria.nombre) == cambios["nombre"].lower(),
                Categoria.id != categoria_id,
            )
        )
        if repetida is not None:
            raise HTTPException(
                status.HTTP_409_CONFLICT, "Ya existe otra categoria con ese nombre"
            )

    for campo, valor in cambios.items():
        setattr(categoria, campo, valor)

    db.commit()
    db.refresh(categoria)
    return categoria


@router.delete("/{categoria_id}", response_model=CategoriaLeer)
def desactivar(categoria_id: int, db: Session = Depends(get_db)):
    """No borra: desactiva. Se bloquea si tiene productos activos colgando."""
    categoria = _buscar(db, categoria_id)

    activos = db.scalar(
        select(func.count(Producto.id)).where(
            Producto.categoria_id == categoria_id, Producto.activo.is_(True)
        )
    )
    if activos:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"La categoria tiene {activos} producto(s) activo(s). "
            "Desactivalos o muevelos de categoria primero.",
        )

    categoria.activo = False
    db.commit()
    db.refresh(categoria)
    return categoria


@router.post("/{categoria_id}/reactivar", response_model=CategoriaLeer)
def reactivar(categoria_id: int, db: Session = Depends(get_db)):
    categoria = _buscar(db, categoria_id)
    categoria.activo = True
    db.commit()
    db.refresh(categoria)
    return categoria
