from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Cliente, Usuario
from app.schemas.cliente import ClienteActualizar, ClienteCrear, ClienteLeer
from app.seguridad import requerir_password_actualizada, solo_admin
from app.texto import columna_plana, patron

# Leer y crear: cualquiera con sesion (el cajero necesita registrar al cliente
# en el mostrador). Editar y desactivar: solo ADMIN.
router = APIRouter(
    prefix="/clientes",
    tags=["Clientes"],
    dependencies=[Depends(requerir_password_actualizada)],
)


def _buscar(db: Session, cliente_id: int) -> Cliente:
    cliente = db.get(Cliente, cliente_id)
    if cliente is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cliente no encontrado")
    return cliente


@router.get("", response_model=list[ClienteLeer])
def listar(
    buscar: str | None = None,
    incluir_inactivos: bool = False,
    db: Session = Depends(get_db),
):
    consulta = select(Cliente).order_by(Cliente.nombre)
    if not incluir_inactivos:
        consulta = consulta.where(Cliente.activo.is_(True))
    if buscar:
        aguja = patron(buscar)
        consulta = consulta.where(
            or_(
                columna_plana(Cliente.nombre).like(aguja),
                columna_plana(Cliente.num_doc).like(aguja),
            )
        )
    return db.scalars(consulta).all()


@router.get("/{cliente_id}", response_model=ClienteLeer)
def obtener(cliente_id: int, db: Session = Depends(get_db)):
    return _buscar(db, cliente_id)


@router.post("", response_model=ClienteLeer, status_code=status.HTTP_201_CREATED)
def crear(datos: ClienteCrear, db: Session = Depends(get_db)):
    num_doc = datos.num_doc.strip()
    repetido = db.scalar(select(Cliente).where(Cliente.num_doc == num_doc))
    if repetido is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"El documento {num_doc} ya lo tiene '{repetido.nombre}'",
        )

    cliente = Cliente(
        **{
            **datos.model_dump(),
            "num_doc": num_doc,
            "nombre": datos.nombre.strip(),
        },
        activo=True,
    )
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    return cliente


@router.put("/{cliente_id}", response_model=ClienteLeer)
def actualizar(
    cliente_id: int,
    datos: ClienteActualizar,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN."""
    cliente = _buscar(db, cliente_id)
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(cliente, campo, valor)
    db.commit()
    db.refresh(cliente)
    return cliente


@router.delete("/{cliente_id}", response_model=ClienteLeer)
def desactivar(
    cliente_id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Solo ADMIN. No borra: desactiva, para no romper las ventas ya hechas."""
    cliente = _buscar(db, cliente_id)
    cliente.activo = False
    db.commit()
    db.refresh(cliente)
    return cliente
