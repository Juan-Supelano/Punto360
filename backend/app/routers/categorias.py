from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Categoria, Producto, Usuario
from app.schemas.categoria import CategoriaActualizar, CategoriaCrear, CategoriaLeer
from app.seguridad import requerir_password_actualizada, solo_admin

router = APIRouter(
    prefix="/categorias",
    tags=["Categorias"],
    # Cualquier usuario con sesion puede LEER las categorias.
    # Crear, editar, desactivar y reactivar exigen ADMIN: se declara por
    # endpoint mas abajo, para que /docs muestre cual pide que rol.
    dependencies=[Depends(requerir_password_actualizada)],
)


def _buscar(db: Session, categoria_id: int) -> Categoria:
    categoria = db.get(Categoria, categoria_id)
    if categoria is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Categoria no encontrada")
    return categoria


def _validar_prefijo_libre(db: Session, prefijo: str, excepto_id: int | None = None):
    consulta = select(Categoria).where(Categoria.prefijo_sku == prefijo)
    if excepto_id is not None:
        consulta = consulta.where(Categoria.id != excepto_id)
    duenna = db.scalar(consulta)
    if duenna is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"El prefijo {prefijo} ya lo usa la categoria '{duenna.nombre}'",
        )


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
def crear(
    datos: CategoriaCrear,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. El prefijo del SKU lo digita el administrador."""
    nombre = datos.nombre.strip()
    repetida = db.scalar(
        select(Categoria).where(func.lower(Categoria.nombre) == nombre.lower())
    )
    if repetida is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Ya existe una categoria con ese nombre"
        )

    _validar_prefijo_libre(db, datos.prefijo_sku)

    categoria = Categoria(
        nombre=nombre,
        descripcion=datos.descripcion,
        prefijo_sku=datos.prefijo_sku,
        activo=True,
    )
    db.add(categoria)
    db.commit()
    db.refresh(categoria)
    return categoria


@router.put("/{categoria_id}", response_model=CategoriaLeer)
def actualizar(
    categoria_id: int,
    datos: CategoriaActualizar,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
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

    if "prefijo_sku" in cambios and cambios["prefijo_sku"] != categoria.prefijo_sku:
        _validar_prefijo_libre(db, cambios["prefijo_sku"], excepto_id=categoria_id)
        # Los productos que ya existen conservan su SKU: cambiar el prefijo solo
        # afecta a los que se creen de aqui en adelante.

    for campo, valor in cambios.items():
        setattr(categoria, campo, valor)

    db.commit()
    db.refresh(categoria)
    return categoria


@router.delete("/{categoria_id}", response_model=CategoriaLeer)
def desactivar(
    categoria_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. No borra: desactiva, y se bloquea si tiene productos activos."""
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
def reactivar(
    categoria_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    categoria = _buscar(db, categoria_id)
    categoria.activo = True
    db.commit()
    db.refresh(categoria)
    return categoria
