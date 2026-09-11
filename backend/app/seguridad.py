"""Hash de contrasenas y emision/verificacion de tokens JWT."""

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session, selectinload

from app.config import settings
from app.database import get_db
from app.models import Usuario

# auto_error=False para poder devolver un mensaje propio en espanol.
esquema_bearer = HTTPBearer(auto_error=False)

CREDENCIALES_INVALIDAS = HTTPException(
    status.HTTP_401_UNAUTHORIZED,
    "Correo o contrasena incorrectos",
    headers={"WWW-Authenticate": "Bearer"},
)


# --- Contrasenas -------------------------------------------------------------
# bcrypt solo mira los primeros 72 bytes; si no se trunca, lanza excepcion.
def hashear(password: str) -> str:
    semilla = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8")[:72], semilla).decode("utf-8")


def verificar(password: str, hash_guardado: str) -> bool:
    try:
        return bcrypt.checkpw(
            password.encode("utf-8")[:72], hash_guardado.encode("utf-8")
        )
    except ValueError:
        # El hash guardado no tiene formato bcrypt (por ejemplo, texto plano).
        return False


# --- Tokens ------------------------------------------------------------------
def crear_token(usuario: Usuario) -> tuple[str, int]:
    """Devuelve (token, segundos_de_vida)."""
    vida = timedelta(minutes=settings.jwt_minutos)
    expira = datetime.now(timezone.utc) + vida
    cuerpo = {
        "sub": str(usuario.id),
        "email": usuario.email,
        "rol": usuario.rol,
        "exp": expira,
    }
    token = jwt.encode(cuerpo, settings.jwt_secreto, algorithm=settings.jwt_algoritmo)
    return token, int(vida.total_seconds())


def usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(esquema_bearer),
    db: Session = Depends(get_db),
) -> Usuario:
    """Dependencia: exige un token valido y devuelve el usuario duenno del token."""
    if credenciales is None:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Falta el token de sesion",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        cuerpo = jwt.decode(
            credenciales.credentials,
            settings.jwt_secreto,
            algorithms=[settings.jwt_algoritmo],
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "La sesion expiro, vuelve a iniciar sesion",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Token invalido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    usuario = (
        db.query(Usuario)
        .options(selectinload(Usuario.comercio))
        .filter(Usuario.id == int(cuerpo["sub"]))
        .one_or_none()
    )
    if usuario is None or not usuario.activo:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "El usuario ya no esta activo"
        )
    return usuario


def solo_admin(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    """Dependencia para las operaciones reservadas al rol ADMIN."""
    if not usuario.es_admin:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Esta accion requiere rol ADMIN",
        )
    return usuario


def requerir_password_actualizada(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    """Dependencia para los routers de negocio normales: si la contrasena
    sigue siendo la temporal que puso un ADMIN, bloquea todo excepto el
    propio perfil (para cambiarla) y auth (para el login)."""
    if usuario.debe_cambiar_password:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Debes cambiar tu contrasena temporal antes de continuar",
        )
    return usuario


def solo_cajero(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    """Quien vende es el cajero. El administrador consulta, no factura:
    asi las ventas siempre tienen un responsable de mostrador identificable."""
    if usuario.rol != "CAJERO":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Solo un usuario con rol CAJERO puede registrar ventas",
        )
    return usuario
