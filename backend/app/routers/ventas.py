from datetime import date, datetime, time, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import (
    Cliente,
    MovimientoInventario,
    Producto,
    Usuario,
    Venta,
    VentaItem,
)
from app.schemas.venta import VentaAnular, VentaCrear, VentaLeer, VentaListada
from app.seguridad import requerir_password_actualizada, solo_admin, solo_cajero, usuario_actual

router = APIRouter(
    prefix="/ventas",
    tags=["Ventas"],
    dependencies=[Depends(requerir_password_actualizada)],
)

CENTAVO = Decimal("0.01")


def _cargar(db: Session, venta_id: int) -> Venta:
    venta = db.scalar(
        select(Venta)
        .options(
            selectinload(Venta.cliente),
            selectinload(Venta.usuario),
            selectinload(Venta.items).selectinload(VentaItem.producto),
        )
        .where(Venta.id == venta_id)
    )
    if venta is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Venta no encontrada")
    return venta


@router.get("", response_model=list[VentaListada])
def listar(
    usuario_id: int | None = None,
    estado: str | None = None,
    desde: date | None = None,
    hasta: date | None = None,
    db: Session = Depends(get_db),
    quien: Usuario = Depends(usuario_actual),
):
    """El ADMIN ve todas las ventas y puede filtrar por cajero.
    El CAJERO solo ve las suyas, aunque pida las de otro."""
    consulta = (
        select(Venta)
        .options(selectinload(Venta.cliente), selectinload(Venta.usuario))
        .order_by(Venta.fecha.desc())
    )

    if quien.es_admin:
        if usuario_id is not None:
            consulta = consulta.where(Venta.usuario_id == usuario_id)
    else:
        consulta = consulta.where(Venta.usuario_id == quien.id)

    if estado:
        consulta = consulta.where(Venta.estado == estado.upper())
    if desde:
        consulta = consulta.where(Venta.fecha >= datetime.combine(desde, time.min))
    if hasta:
        consulta = consulta.where(Venta.fecha <= datetime.combine(hasta, time.max))

    return db.scalars(consulta).all()


@router.get("/resumen")
def resumen(
    desde: date | None = None,
    hasta: date | None = None,
    db: Session = Depends(get_db),
    quien: Usuario = Depends(usuario_actual),
):
    """Totales para las tarjetas de arriba. El cajero solo ve lo suyo."""
    base = select(
        func.count(Venta.id),
        func.coalesce(func.sum(Venta.total), 0),
    ).where(Venta.estado == "PAGADA")

    if not quien.es_admin:
        base = base.where(Venta.usuario_id == quien.id)
    if desde:
        base = base.where(Venta.fecha >= datetime.combine(desde, time.min))
    if hasta:
        base = base.where(Venta.fecha <= datetime.combine(hasta, time.max))

    cantidad, total = db.execute(base).one()

    anuladas_q = select(func.count(Venta.id)).where(Venta.estado == "ANULADA")
    if not quien.es_admin:
        anuladas_q = anuladas_q.where(Venta.usuario_id == quien.id)

    return {
        "ventas": cantidad,
        "total": total,
        "anuladas": db.scalar(anuladas_q),
        "promedio": (total / cantidad) if cantidad else 0,
    }


@router.get("/por-cajero")
def por_cajero(
    desde: date | None = None,
    hasta: date | None = None,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Cuanto vendio cada cajero. Solo ADMIN."""
    consulta = (
        select(
            Usuario.id,
            Usuario.nombre,
            func.count(Venta.id),
            func.coalesce(func.sum(Venta.total), 0),
        )
        .join(Venta, Venta.usuario_id == Usuario.id)
        .where(Venta.estado == "PAGADA")
        .group_by(Usuario.id, Usuario.nombre)
        .order_by(func.coalesce(func.sum(Venta.total), 0).desc())
    )
    if desde:
        consulta = consulta.where(Venta.fecha >= datetime.combine(desde, time.min))
    if hasta:
        consulta = consulta.where(Venta.fecha <= datetime.combine(hasta, time.max))

    return [
        {"usuario_id": f[0], "nombre": f[1], "ventas": f[2], "total": f[3]}
        for f in db.execute(consulta).all()
    ]


@router.get("/{venta_id}", response_model=VentaLeer)
def obtener(
    venta_id: int,
    db: Session = Depends(get_db),
    quien: Usuario = Depends(usuario_actual),
):
    venta = _cargar(db, venta_id)
    if not quien.es_admin and venta.usuario_id != quien.id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Esa venta la registro otro cajero"
        )
    return venta


@router.post("", response_model=VentaLeer, status_code=status.HTTP_201_CREATED)
def crear(
    datos: VentaCrear,
    db: Session = Depends(get_db),
    cajero: Usuario = Depends(solo_cajero),
):
    """Registrar una venta es UNA sola transaccion:
    crea la venta, sus items con el precio congelado, descuenta el stock y
    escribe el kardex. Si un producto no alcanza, no se guarda nada.
    """
    if datos.cliente_id is not None:
        cliente = db.get(Cliente, datos.cliente_id)
        if cliente is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "El cliente no existe")
        if not cliente.activo:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "El cliente esta desactivado"
            )

    # venta_item tiene UNIQUE (venta_id, producto_id): un producto, una linea.
    vistos: set[int] = set()
    for linea in datos.items:
        if linea.producto_id in vistos:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Un mismo producto aparece dos veces. Junta las cantidades en una linea.",
            )
        vistos.add(linea.producto_id)

    # Se valida TODO antes de insertar la venta. El numero sale de una secuencia
    # de PostgreSQL, y las secuencias no se devuelven al hacer rollback: si se
    # creara la venta primero y luego fallara por stock, quedaria un hueco en la
    # numeracion de facturas por cada intento fallido.
    preparadas = []
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
        if producto.stock_actual < linea.cantidad:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"Stock insuficiente de {producto.sku} ({producto.nombre}): "
                f"pediste {linea.cantidad} y hay {producto.stock_actual}",
            )
        preparadas.append((producto, linea.cantidad))

    venta = Venta(
        cliente_id=datos.cliente_id,
        subtotal=Decimal("0"),
        total_iva=Decimal("0"),
        total=Decimal("0"),
        metodo_pago=datos.metodo_pago,
        estado="PAGADA",
        observaciones=datos.observaciones,
        usuario_id=cajero.id,
    )
    db.add(venta)
    db.flush()  # asigna id y numero sin cerrar la transaccion

    subtotal = Decimal("0")
    total_iva = Decimal("0")

    for producto, cantidad in preparadas:
        # Precio e IVA se congelan: si manana cambian, esta venta no se mueve.
        precio = Decimal(producto.precio_venta).quantize(CENTAVO)
        iva_pct = Decimal(producto.iva_pct)
        sub_linea = (precio * cantidad).quantize(CENTAVO)
        iva_linea = (sub_linea * iva_pct / Decimal("100")).quantize(CENTAVO)

        db.add(
            VentaItem(
                venta_id=venta.id,
                producto_id=producto.id,
                cantidad=Decimal(cantidad),
                precio_unitario=precio,
                iva_pct=iva_pct,
                subtotal_linea=sub_linea,
                iva_linea=iva_linea,
                total_linea=sub_linea + iva_linea,
            )
        )

        anterior = producto.stock_actual
        producto.stock_actual = anterior - cantidad

        db.add(
            MovimientoInventario(
                producto_id=producto.id,
                tipo="VENTA",
                cantidad=Decimal(cantidad),
                stock_anterior=anterior,
                stock_resultante=producto.stock_actual,
                venta_id=venta.id,
                usuario_id=cajero.id,
                motivo=f"Venta {venta.numero}",
            )
        )

        subtotal += sub_linea
        total_iva += iva_linea

    venta.subtotal = subtotal
    venta.total_iva = total_iva
    venta.total = subtotal + total_iva

    db.commit()
    return _cargar(db, venta.id)


@router.post("/{venta_id}/anular", response_model=VentaLeer)
def anular(
    venta_id: int,
    datos: VentaAnular,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(solo_admin),
):
    """Nada se borra: la venta queda ANULADA y la mercancia vuelve al stock.
    Solo ADMIN, para que un cajero no pueda deshacer sus propias ventas.
    """
    venta = _cargar(db, venta_id)

    if venta.estado == "ANULADA":
        raise HTTPException(status.HTTP_409_CONFLICT, "La venta ya estaba anulada")

    for item in venta.items:
        producto = db.get(Producto, item.producto_id)
        cantidad = int(item.cantidad)
        anterior = producto.stock_actual
        producto.stock_actual = anterior + cantidad

        db.add(
            MovimientoInventario(
                producto_id=producto.id,
                tipo="ANULACION",
                cantidad=Decimal(cantidad),
                stock_anterior=anterior,
                stock_resultante=producto.stock_actual,
                venta_id=venta.id,
                usuario_id=admin.id,
                motivo=f"Anulacion venta {venta.numero}: {datos.motivo.strip()}",
            )
        )

    # El CHECK de la base exige anulada_en cuando el estado es ANULADA.
    venta.estado = "ANULADA"
    venta.anulada_en = datetime.now(timezone.utc)
    venta.motivo_anula = datos.motivo.strip()

    db.commit()
    return _cargar(db, venta.id)
