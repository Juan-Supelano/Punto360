from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Categoria
from app.schemas.categoria import CategoriaActualizar, CategoriaCrear, CategoriaLeer

router = APIRouter(prefix="/categorias", tags=["Categorias"])


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
    existe = db.scalar(select(Categoria).where(Categoria.nombre == datos.nombre))
    if existe is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe una categoria con ese nombre")
    categoria = Categoria(**datos.model_dump())
    db.add(categoria)
    db.commit()
    db.refresh(categoria)
    return categoria


@router.put("/{categoria_id}", response_model=CategoriaLeer)
def actualizar(categoria_id: int, datos: CategoriaActualizar, db: Session = Depends(get_db)):
    categoria = _buscar(db, categoria_id)
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(categoria, campo, valor)
    db.commit()
    db.refresh(categoria)
    return categoria


@router.delete("/{categoria_id}", response_model=CategoriaLeer)
def desactivar(categoria_id: int, db: Session = Depends(get_db)):
    """No borra el registro: lo marca como inactivo."""
    categoria = _buscar(db, categoria_id)
    categoria.activo = False
    db.commit()
    db.refresh(categoria)
    return categoria
