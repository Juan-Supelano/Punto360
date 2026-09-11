"""Desglose del IVA de una linea.

Un precio puede venir de dos formas:

  - IVA INCLUIDO (lo normal en el mostrador): el boligrafo cuesta 1200 y eso
    es lo que paga el cliente. La factura tiene que descomponer esos 1200 en
    base + impuesto, no sumarle nada encima.

  - IVA EXCLUIDO (comun entre empresas): los 1200 son la base y el impuesto
    se suma aparte, asi que el cliente paga 1428.

El calculo del IVA incluido se hace al reves: base = total / (1 + tasa).
Y el impuesto se obtiene RESTANDO (total - base), nunca multiplicando la base
otra vez, porque al redondear a dos decimales base + iva podria no dar el
total exacto y la factura quedaria descuadrada por un peso.
"""

from decimal import ROUND_HALF_UP, Decimal

CENTAVO = Decimal("0.01")
CIEN = Decimal("100")


def _redondear(valor: Decimal) -> Decimal:
    """Redondeo comercial: 0.5 sube. El de Python por defecto es bancario."""
    return Decimal(valor).quantize(CENTAVO, rounding=ROUND_HALF_UP)


def desglosar(
    precio_unitario: Decimal,
    cantidad: int,
    iva_pct: Decimal,
    incluye_iva: bool,
) -> tuple[Decimal, Decimal, Decimal]:
    """Devuelve (subtotal_linea, iva_linea, total_linea) ya redondeados.

    Se garantiza siempre que subtotal + iva == total.
    """
    precio = Decimal(precio_unitario)
    tasa = Decimal(iva_pct)
    bruto = _redondear(precio * cantidad)

    if incluye_iva:
        # El precio ya trae el impuesto: hay que sacarlo de adentro.
        subtotal = _redondear(bruto / (Decimal("1") + tasa / CIEN))
        iva = bruto - subtotal
        total = bruto
    else:
        subtotal = bruto
        iva = _redondear(subtotal * tasa / CIEN)
        total = subtotal + iva

    return subtotal, iva, total


def base_sin_iva(valor: Decimal, iva_pct: Decimal, incluye_iva: bool) -> Decimal:
    """Costo unitario limpio de impuesto, para guardarlo en producto.costo.

    El costo del inventario nunca lleva IVA: ese impuesto es descontable, no
    hace parte de lo que vale la mercancia.
    """
    if not incluye_iva:
        return _redondear(valor)
    return _redondear(Decimal(valor) / (Decimal("1") + Decimal(iva_pct) / CIEN))
