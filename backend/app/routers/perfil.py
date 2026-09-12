"""Perfil del propio usuario. A diferencia de app/routers/usuarios.py (solo
ADMIN, gestiona a cualquiera), aqui cada usuario ve y edita SUS propios datos.

Usa `usuario_actual` (no `requerir_password_actualizada`): con contrasena
temporal el usuario debe poder entrar aqui a cambiarla."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Usuario
from app.schemas.usuario import CambiarPassword, PerfilActualizar, PerfilOut
from app.seguridad import hashear, usuario_actual, verificar

router = APIRouter(prefix="/perfil", tags=["Perfil"])


@router.get("/yo", response_model=PerfilOut)
def ver_perfil(usuario: Usuario = Depends(usuario_actual)):
    return usuario


@router.put("/yo", response_model=PerfilOut)
def actualizar_perfil(
    datos: PerfilActualizar,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(usuario_actual),
):
    """La foto se guarda como URL (igual que el logo de la empresa): el
    usuario sube la imagen a donde sea (por ejemplo Cloud Storage) y pega
    aqui su direccion publica."""
    usuario.nombre = datos.nombre.strip()
    usuario.foto_url = datos.foto_url.strip() if datos.foto_url else None
    db.commit()
    db.refresh(usuario)
    return usuario


@router.post("/cambiar-password", response_model=PerfilOut)
def cambiar_password(
    datos: CambiarPassword,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(usuario_actual),
):
    if not verificar(datos.password_actual, usuario.password_hash):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "La contrasena actual no es correcta"
        )

    usuario.password_hash = hashear(datos.password_nueva)
    usuario.debe_cambiar_password = False
    db.commit()
    db.refresh(usuario)
    return usuario
