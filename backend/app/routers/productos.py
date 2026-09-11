from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import Categoria, Producto, Usuario
from app.models.producto import UNIDADES
from app.schemas.producto import ProductoActualizar, ProductoCrear, ProductoLeer
from app.seguridad import usuario_actual

router = APIRouter(
    prefix="/productos",
    tags=["Productos"],
    dependencies=[Depends(usuario_actual)],
)


def _buscar(db: Session, producto_id: int) -> Producto:
    producto = db.get(Producto, producto_id)
    if producto is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Producto no encontrado")
    return producto


def _buscar_categoria(db: Session, categoria_id: int) -> Categoria:
    categoria = db.get(Categoria, categoria_id)
    if categoria is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La categoria no existe")
    if not categoria.activo:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "La categoria esta desactivada"
        )
    return categoria


def _validar_unidad(unidad: str | None) -> None:
    if unidad is not None and unidad not in UNIDADES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Unidad de medida invalida. Use una de: {', '.join(UNIDADES)}",
        )


def _siguiente_sku(db: Session, categoria: Categoria) -> str:
    """Arma el SKU a partir del prefijo de la categoria: BEB-001, BEB-002...

    Se mira el consecutivo mas alto que ya exista con ese prefijo, incluyendo
    productos inactivos, para no reutilizar nunca un codigo dado de baja.
    """
    prefijo = categoria.prefijo_sku
    usados = db.scalars(
        select(Producto.sku).where(Producto.sku.like(f"{prefijo}-%"))
    ).all()

    mayor = 0
    for sku in usados:
        cola = sku.rsplit("-", 1)[-1]
        if cola.isdigit():
            mayor = max(mayor, int(cola))

    return f"{prefijo}-{mayor + 1:03d}"


@router.get("", response_model=list[ProductoLeer])
def listar(
    categoria_id: int | None = None,
    buscar: str | None = None,
    solo_stock_bajo: bool = False,
    incluir_inactivos: bool = False,
    db: Session = Depends(get_db),
):
    consulta = (
        select(Producto)
        .options(selectinload(Producto.categoria))
        .order_by(Producto.nombre)
    )
    if not incluir_inactivos:
        consulta = consulta.where(Producto.activo.is_(True))
    if categoria_id is not None:
        consulta = consulta.where(Producto.categoria_id == categoria_id)
    if buscar:
        patron = f"%{buscar}%"
        consulta = consulta.where(
            or_(Producto.nombre.ilike(patron), Producto.sku.ilike(patron))
        )
    if solo_stock_bajo:
        consulta = consulta.where(Producto.stock_actual <= Producto.stock_minimo)
    return db.scalars(consulta).all()


# Va ANTES de /{producto_id}: si no, FastAPI intenta leer "siguiente-sku"
# como un id entero y responde 422.
@router.get("/siguiente-sku")
def siguiente_sku(categoria_id: int = Query(), db: Session = Depends(get_db)):
    """Vista previa del SKU que se asignaria. No reserva nada."""
    categoria = _buscar_categoria(db, categoria_id)
    return {
        "categoria_id": categoria.id,
        "prefijo_sku": categoria.prefijo_sku,
        "sku": _siguiente_sku(db, categoria),
    }


@router.get("/{producto_id}", response_model=ProductoLeer)
def obtener(producto_id: int, db: Session = Depends(get_db)):
    return _buscar(db, producto_id)


@router.post("", response_model=ProductoLeer, status_code=status.HTTP_201_CREATED)
def crear(datos: ProductoCrear, db: Session = Depends(get_db)):
    categoria = _buscar_categoria(db, datos.categoria_id)
    _validar_unidad(datos.unidad_medida)

    campos = datos.model_dump(exclude={"sku"})
    manual = datos.sku.strip().upper() if datos.sku else None

    if manual and db.scalar(select(Producto).where(Producto.sku == manual)):
        raise HTTPException(
            status.HTTP_409_CONFLICT, f"Ya existe un producto con el SKU {manual}"
        )

    # Si dos cajeros crean productos a la vez pueden calcular el mismo
    # consecutivo. El UNIQUE de la base rechaza al segundo y aqui se reintenta.
    for _ in range(5):
        sku = manual or _siguiente_sku(db, categoria)
        producto = Producto(**campos, sku=sku, activo=True)
        db.add(producto)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            if manual:
                raise HTTPException(
                    status.HTTP_409_CONFLICT,
                    f"Ya existe un producto con el SKU {manual}",
                )
            continue
        db.refresh(producto)
        return producto

    raise HTTPException(
        status.HTTP_409_CONFLICT,
        "No se pudo asignar un SKU libre. Intenta de nuevo.",
    )


@router.put("/{producto_id}", response_model=ProductoLeer)
def actualizar(
    producto_id: int, datos: ProductoActualizar, db: Session = Depends(get_db)
):
    producto = _buscar(db, producto_id)
    cambios = datos.model_dump(exclude_unset=True)

    if "categoria_id" in cambios:
        _buscar_categoria(db, cambios["categoria_id"])
        # El SKU NO se recalcula al mover un producto de categoria: ya puede
        # estar impreso en etiquetas o usado por un proveedor.
    if "unidad_medida" in cambios:
        _validar_unidad(cambios["unidad_medida"])
    if "sku" in cambios:
        cambios["sku"] = cambios["sku"].strip().upper()
        repetido = db.scalar(
            select(Producto).where(
                Producto.sku == cambios["sku"], Producto.id != producto_id
            )
        )
        if repetido is not None:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"Ya existe otro producto con el SKU {cambios['sku']}",
            )

    for campo, valor in cambios.items():
        setattr(producto, campo, valor)

    db.commit()
    db.refresh(producto)
    return producto


@router.patch("/{producto_id}/stock", response_model=ProductoLeer)
def ajustar_stock(
    producto_id: int,
    cantidad: int = Query(
        description="Positivo suma unidades, negativo las resta."
    ),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(usuario_actual),
):
    """Ajuste manual de inventario. El kardex se conectara aqui mas adelante."""
    producto = _buscar(db, producto_id)
    nuevo = producto.stock_actual + cantidad
    if nuevo < 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"No hay stock suficiente. Disponible: {producto.stock_actual}",
        )
    producto.stock_actual = nuevo
    db.commit()
    db.refresh(producto)
    return producto


@router.delete("/{producto_id}", response_model=ProductoLeer)
def desactivar(producto_id: int, db: Session = Depends(get_db)):
    """No borra el registro: lo marca como inactivo."""
    producto = _buscar(db, producto_id)
    producto.activo = False
    db.commit()
    db.refresh(producto)
    return producto


@router.post("/{producto_id}/reactivar", response_model=ProductoLeer)
def reactivar(producto_id: int, db: Session = Depends(get_db)):
    producto = _buscar(db, producto_id)
    producto.activo = True
    db.commit()
    db.refresh(producto)
    return producto
