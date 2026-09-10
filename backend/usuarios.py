"""Crea o cambia la contrasena de un usuario del POS.

Los dos usuarios que ya estan en la base tienen un password_hash que no sabemos
con que se genero. Con este script les pones una contrasena conocida (queda
guardada como hash bcrypt, nunca en texto plano).

Uso, desde cuadre-pos\\backend con el venv activado:

    python usuarios.py listar
    python usuarios.py clave admin@cuadrepos.co MiClave123
    python usuarios.py crear cajero@cuadrepos.co "Ana Torres" MiClave123 CAJERO
"""

import sys

from sqlalchemy import select

from app.database import SessionLocal
from app.models import Comercio, Usuario
from app.seguridad import hashear

ROLES = ("ADMIN", "CAJERO")


def listar(db):
    usuarios = db.scalars(select(Usuario).order_by(Usuario.id)).all()
    if not usuarios:
        print("No hay usuarios en la base.")
        return
    print(f"{'id':<4} {'email':<32} {'nombre':<24} {'rol':<8} activo")
    for u in usuarios:
        print(f"{u.id:<4} {u.email:<32} {u.nombre:<24} {u.rol:<8} {u.activo}")


def cambiar_clave(db, email, password):
    usuario = db.scalar(select(Usuario).where(Usuario.email == email.lower()))
    if usuario is None:
        print(f"No existe un usuario con el correo {email}")
        return
    usuario.password_hash = hashear(password)
    db.commit()
    print(f"Contrasena actualizada para {usuario.email} (rol {usuario.rol}).")


def crear(db, email, nombre, password, rol):
    if rol not in ROLES:
        print(f"Rol invalido. Use uno de: {', '.join(ROLES)}")
        return
    if db.scalar(select(Usuario).where(Usuario.email == email.lower())):
        print(f"Ya existe un usuario con el correo {email}")
        return

    comercio = db.scalar(select(Comercio).limit(1))
    if comercio is None:
        print("Falta la fila de configuracion_comercio. Corre migracion_comercio.sql")
        return

    usuario = Usuario(
        email=email.lower(),
        nombre=nombre,
        password_hash=hashear(password),
        rol=rol,
        activo=True,
        comercio_id=comercio.id,
    )
    db.add(usuario)
    db.commit()
    print(f"Usuario {usuario.email} creado con rol {rol}.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return

    accion = sys.argv[1]
    db = SessionLocal()
    try:
        if accion == "listar":
            listar(db)
        elif accion == "clave" and len(sys.argv) == 4:
            cambiar_clave(db, sys.argv[2], sys.argv[3])
        elif accion == "crear" and len(sys.argv) == 6:
            crear(db, sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5].upper())
        else:
            print(__doc__)
    finally:
        db.close()


if __name__ == "__main__":
    main()
