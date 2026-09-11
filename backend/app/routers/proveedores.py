from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Compra, Proveedor, Usuario
from app.schemas.proveedor import (
    ProveedorActualizar,
    ProveedorCrear,
    ProveedorLeer,
)
from app.seguridad import solo_admin, usuario_actual

# Consultar proveedores: cualquiera con sesion, tambien el cajero.
# Crear, editar y desactivar: solo ADMIN (se declara en cada endpoint).
router = APIRouter(
    prefix="/proveedores",
    tags=["Proveedores"],
    dependencies=[Depends(usuario_actual)],
)


def _buscar(db: Session, proveedor_id: int) -> Proveedor:
    proveedor = db.get(Proveedor, proveedor_id)
    if proveedor is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Proveedor no encontrado")
    return proveedor


def _validar_nit_libre(db: Session, nit: str, excepto_id: int | None = None):
    consulta = select(Proveedor).where(Proveedor.nit == nit)
    if excepto_id is not None:
        consulta = consulta.where(Proveedor.id != excepto_id)
    duenno = db.scalar(consulta)
    if duenno is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"El NIT {nit} ya lo tiene el proveedor '{duenno.nombre}'",
        )


@router.get("", response_model=list[ProveedorLeer])
def listar(
    buscar: str | None = None,
    incluir_inactivos: bool = False,
    db: Session = Depends(get_db),
):
    consulta = select(Proveedor).order_by(Proveedor.nombre)
    if not incluir_inactivos:
        consulta = consulta.where(Proveedor.activo.is_(True))
    if buscar:
        patron = f"%{buscar}%"
        consulta = consulta.where(
            or_(Proveedor.nombre.ilike(patron), Proveedor.nit.ilike(patron))
        )
    return db.scalars(consulta).all()


@router.get("/{proveedor_id}", response_model=ProveedorLeer)
def obtener(proveedor_id: int, db: Session = Depends(get_db)):
    return _buscar(db, proveedor_id)


@router.post("", response_model=ProveedorLeer, status_code=status.HTTP_201_CREATED)
def crear(
    datos: ProveedorCrear,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    nit = datos.nit.strip()
    _validar_nit_libre(db, nit)

    proveedor = Proveedor(
        **{**datos.model_dump(), "nit": nit, "nombre": datos.nombre.strip()},
        activo=True,
    )
    db.add(proveedor)
    db.commit()
    db.refresh(proveedor)
    return proveedor


@router.put("/{proveedor_id}", response_model=ProveedorLeer)
def actualizar(
    proveedor_id: int,
    datos: ProveedorActualizar,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    proveedor = _buscar(db, proveedor_id)
    cambios = datos.model_dump(exclude_unset=True)

    if "nit" in cambios:
        cambios["nit"] = cambios["nit"].strip()
        _validar_nit_libre(db, cambios["nit"], excepto_id=proveedor_id)
    if "nombre" in cambios:
        cambios["nombre"] = cambios["nombre"].strip()

    for campo, valor in cambios.items():
        setattr(proveedor, campo, valor)

    db.commit()
    db.refresh(proveedor)
    return proveedor


@router.delete("/{proveedor_id}", response_model=ProveedorLeer)
def desactivar(
    proveedor_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. No borra: desactiva. Las compras ya registradas siguen ahi."""
    proveedor = _buscar(db, proveedor_id)
    proveedor.activo = False
    db.commit()
    db.refresh(proveedor)
    return proveedor


@router.post("/{proveedor_id}/reactivar", response_model=ProveedorLeer)
def reactivar(
    proveedor_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    proveedor = _buscar(db, proveedor_id)
    proveedor.activo = True
    db.commit()
    db.refresh(proveedor)
    return proveedor


@router.get("/{proveedor_id}/resumen")
def resumen(proveedor_id: int, db: Session = Depends(get_db)):
    """Cuanto se le ha comprado. Util para la vista de detalle."""
    proveedor = _buscar(db, proveedor_id)
    fila = db.execute(
        select(
            func.count(Compra.id),
            func.coalesce(func.sum(Compra.total), 0),
            func.max(Compra.fecha),
        ).where(Compra.proveedor_id == proveedor.id, Compra.estado == "RECIBIDA")
    ).one()
    return {
        "proveedor_id": proveedor.id,
        "compras": fila[0],
        "total_comprado": fila[1],
        "ultima_compra": fila[2],
    }
