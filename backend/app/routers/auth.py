from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import Comercio, Usuario
from app.schemas.auth import (
    ComercioActualizar,
    ComercioLeer,
    LoginPeticion,
    LoginRespuesta,
    UsuarioLeer,
)
from app.seguridad import (
    CREDENCIALES_INVALIDAS,
    crear_token,
    solo_admin,
    usuario_actual,
    verificar,
)

router = APIRouter(prefix="/auth", tags=["Autenticacion"])


@router.post("/login", response_model=LoginRespuesta)
def login(datos: LoginPeticion, db: Session = Depends(get_db)):
    consulta = (
        select(Usuario)
        .options(selectinload(Usuario.comercio))
        .where(Usuario.email == datos.email.lower())
    )
    usuario = db.scalar(consulta)

    # El mismo mensaje si el correo no existe o la contrasena esta mal:
    # no le decimos a un atacante cuales correos estan registrados.
    if usuario is None or not verificar(datos.password, usuario.password_hash):
        raise CREDENCIALES_INVALIDAS

    if not usuario.activo:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "El usuario esta desactivado")

    usuario.ultimo_acceso = datetime.now(timezone.utc).replace(tzinfo=None)
    db.commit()
    db.refresh(usuario)

    token, segundos = crear_token(usuario)
    return LoginRespuesta(access_token=token, expira_en=segundos, usuario=usuario)


@router.get("/yo", response_model=UsuarioLeer)
def yo(usuario: Usuario = Depends(usuario_actual)):
    """Sirve para que el frontend valide el token guardado al recargar la pagina."""
    return usuario


@router.get("/comercio", response_model=ComercioLeer)
def ver_comercio(usuario: Usuario = Depends(usuario_actual)):
    return usuario.comercio


@router.put("/comercio", response_model=ComercioLeer)
def actualizar_comercio(
    datos: ComercioActualizar,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    comercio = db.get(Comercio, admin.comercio_id)
    if comercio is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No hay datos de la empresa")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(comercio, campo, valor)

    db.commit()
    db.refresh(comercio)
    return comercio
