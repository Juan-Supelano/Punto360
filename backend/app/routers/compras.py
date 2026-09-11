from datetime import date, datetime, time
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import (
    Compra,
    CompraItem,
    MovimientoInventario,
    Producto,
    Proveedor,
    Usuario,
)
from app.schemas.compra import CompraAnular, CompraCrear, CompraLeer, CompraListada
from app.seguridad import requerir_password_actualizada, solo_admin

# Consultar compras: cualquiera con sesion, tambien el cajero.
# Registrar y anular: solo ADMIN (se declara en cada endpoint).
router = APIRouter(
    prefix="/compras",
    tags=["Compras"],
    dependencies=[Depends(requerir_password_actualizada)],
)

CENTAVO = Decimal("0.01")


def _cargar(db: Session, compra_id: int) -> Compra:
    compra = db.scalar(
        select(Compra)
        .options(
            selectinload(Compra.proveedor),
            selectinload(Compra.items).selectinload(CompraItem.producto),
        )
        .where(Compra.id == compra_id)
    )
    if compra is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Compra no encontrada")
    return compra


@router.get("", response_model=list[CompraListada])
def listar(
    proveedor_id: int | None = None,
    estado: str | None = None,
    desde: date | None = None,
    hasta: date | None = None,
    db: Session = Depends(get_db),
):
    consulta = (
        select(Compra)
        .options(selectinload(Compra.proveedor))
        .order_by(Compra.fecha.desc())
    )
    if proveedor_id is not None:
        consulta = consulta.where(Compra.proveedor_id == proveedor_id)
    if estado:
        consulta = consulta.where(Compra.estado == estado.upper())
    if desde:
        consulta = consulta.where(Compra.fecha >= datetime.combine(desde, time.min))
    if hasta:
        consulta = consulta.where(Compra.fecha <= datetime.combine(hasta, time.max))
    return db.scalars(consulta).all()


@router.get("/{compra_id}", response_model=CompraLeer)
def obtener(compra_id: int, db: Session = Depends(get_db)):
    return _cargar(db, compra_id)


@router.post("", response_model=CompraLeer, status_code=status.HTTP_201_CREATED)
def crear(
    datos: CompraCrear,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Registrar una compra es UNA sola transaccion:
    crea la compra, sus items, suma el stock y escribe el kardex.
    Si algo falla, no queda nada a medias.
    """
    proveedor = db.get(Proveedor, datos.proveedor_id)
    if proveedor is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "El proveedor no existe")
    if not proveedor.activo:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "El proveedor esta desactivado"
        )

    factura = datos.numero_factura.strip().upper()
    repetida = db.scalar(
        select(Compra).where(
            Compra.proveedor_id == proveedor.id, Compra.numero_factura == factura
        )
    )
    if repetida is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"La factura {factura} ya fue registrada para {proveedor.nombre}",
        )

    # Un producto no puede venir dos veces: se suman las cantidades antes.
    vistos: dict[int, int] = {}
    for linea in datos.items:
        if linea.producto_id in vistos:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Un mismo producto aparece dos veces. Junta las cantidades en una linea.",
            )
        vistos[linea.producto_id] = 1

    compra = Compra(
        proveedor_id=proveedor.id,
        numero_factura=factura,
        subtotal=Decimal("0"),
        total_iva=Decimal("0"),
        total=Decimal("0"),
        estado="RECIBIDA",
    )
    db.add(compra)
    db.flush()  # asigna compra.id sin cerrar la transaccion

    subtotal = Decimal("0")
    total_iva = Decimal("0")

    for linea in datos.items:
        producto = db.get(Producto, linea.producto_id)
        if producto is None:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"El producto {linea.producto_id} no existe",
            )
        if not producto.activo:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"El producto {producto.sku} esta desactivado",
            )

        costo = Decimal(linea.costo_unitario).quantize(CENTAVO)
        subtotal_linea = (costo * linea.cantidad).quantize(CENTAVO)
        iva_linea = (subtotal_linea * producto.iva_pct / Decimal("100")).quantize(
            CENTAVO
        )

        db.add(
            CompraItem(
                compra_id=compra.id,
                producto_id=producto.id,
                cantidad=Decimal(linea.cantidad),
                costo_unitario=costo,
                subtotal_linea=subtotal_linea,
            )
        )

        # Entrada de inventario + kardex.
        anterior = producto.stock_actual
        producto.stock_actual = anterior + linea.cantidad
        # Costo del producto = ultimo costo de compra. Es lo habitual en un POS
        # de mostrador; un promedio ponderado seria mas fino pero mas pesado.
        producto.costo = costo

        db.add(
            MovimientoInventario(
                producto_id=producto.id,
                tipo="COMPRA",
                cantidad=Decimal(linea.cantidad),
                stock_anterior=anterior,
                stock_resultante=producto.stock_actual,
                usuario_id=admin.id,
                motivo=f"Compra {factura} - {proveedor.nombre}",
            )
        )

        subtotal += subtotal_linea
        total_iva += iva_linea

    compra.subtotal = subtotal
    compra.total_iva = total_iva
    compra.total = subtotal + total_iva

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "No se pudo guardar la compra. Revisa la factura y los productos.",
        )

    return _cargar(db, compra.id)


@router.post("/{compra_id}/anular", response_model=CompraLeer)
def anular(
    compra_id: int,
    datos: CompraAnular,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Nada se borra: la compra queda ANULADA y el stock se devuelve.

    Si ya se vendio parte de lo comprado, el stock no alcanza para revertir
    y la anulacion se rechaza: hay que hacer un ajuste manual.
    """
    compra = _cargar(db, compra_id)

    if compra.estado == "ANULADA":
        raise HTTPException(status.HTTP_409_CONFLICT, "La compra ya estaba anulada")

    motivo = (datos.motivo or "").strip() or "Sin motivo registrado"

    for item in compra.items:
        producto = db.get(Producto, item.producto_id)
        cantidad = int(item.cantidad)
        anterior = producto.stock_actual
        resultante = anterior - cantidad

        if resultante < 0:
            db.rollback()
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"No se puede anular: de {producto.sku} entraron {cantidad} "
                f"pero solo quedan {anterior} en stock. Parte ya se vendio.",
            )

        producto.stock_actual = resultante
        db.add(
            MovimientoInventario(
                producto_id=producto.id,
                tipo="ANULACION",
                cantidad=Decimal(cantidad),
                stock_anterior=anterior,
                stock_resultante=resultante,
                usuario_id=admin.id,
                motivo=f"Anulacion compra {compra.numero_factura}: {motivo}",
            )
        )

    compra.estado = "ANULADA"
    db.commit()
    return _cargar(db, compra.id)
