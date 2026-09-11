"""CRUD de usuarios del comercio (cajeros y administradores). Reservado a ADMIN."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Usuario
from app.schemas.usuario import UsuarioActualizar, UsuarioCrear, UsuarioOut
from app.seguridad import hashear, solo_admin

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


def _buscar(db: Session, admin: Usuario, usuario_id: int) -> Usuario:
    usuario = db.get(Usuario, usuario_id)
    if usuario is None or usuario.comercio_id != admin.comercio_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuario no encontrado")
    return usuario


@router.get("", response_model=list[UsuarioOut])
def listar(
    buscar: str | None = None,
    incluir_inactivos: bool = False,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    consulta = (
        select(Usuario)
        .where(Usuario.comercio_id == admin.comercio_id)
        .order_by(Usuario.nombre)
    )
    if not incluir_inactivos:
        consulta = consulta.where(Usuario.activo.is_(True))
    if buscar:
        patron = f"%{buscar}%"
        consulta = consulta.where(
            or_(Usuario.nombre.ilike(patron), Usuario.email.ilike(patron))
        )
    return db.scalars(consulta).all()


@router.post("", response_model=UsuarioOut, status_code=status.HTTP_201_CREATED)
def crear(
    datos: UsuarioCrear,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. El correo queda unico dentro de toda la base (login por correo)."""
    email = datos.email.lower()
    existe = db.scalar(select(Usuario).where(Usuario.email == email))
    if existe:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe un usuario con ese correo")

    nuevo = Usuario(
        email=email,
        nombre=datos.nombre.strip(),
        rol=datos.rol,
        password_hash=hashear(datos.password),
        activo=True,
        comercio_id=admin.comercio_id,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@router.put("/{usuario_id}", response_model=UsuarioOut)
def actualizar(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. Nadie puede quitarse a si mismo el rol de administrador."""
    usuario = _buscar(db, admin, usuario_id)
    cambios = datos.model_dump(exclude_unset=True)

    if usuario.id == admin.id and cambios.get("rol") == "CAJERO":
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "No puedes quitarte tu propio rol de administrador"
        )
    if usuario.id == admin.id and cambios.get("activo") is False:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "No puedes desactivar tu propia cuenta"
        )

    if "nombre" in cambios:
        cambios["nombre"] = cambios["nombre"].strip()

    for campo, valor in cambios.items():
        setattr(usuario, campo, valor)

    db.commit()
    db.refresh(usuario)
    return usuario


@router.delete("/{usuario_id}", response_model=UsuarioOut)
def desactivar(
    usuario_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. No borra: desactiva. Nadie puede desactivar su propia cuenta."""
    usuario = _buscar(db, admin, usuario_id)
    if usuario.id == admin.id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "No puedes desactivar tu propia cuenta"
        )
    usuario.activo = False
    db.commit()
    db.refresh(usuario)
    return usuario


@router.post("/{usuario_id}/reactivar", response_model=UsuarioOut)
def reactivar(
    usuario_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    usuario = _buscar(db, admin, usuario_id)
    usuario.activo = True
    db.commit()
    db.refresh(usuario)
    return usuario
