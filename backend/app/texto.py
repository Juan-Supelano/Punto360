"""Busqueda que ignora tildes, mayusculas y la enne.

En el mostrador nadie escribe "Panaderia" con tilde, y el cajero no deberia
tener que adivinar como quedo escrito el producto en la base. Asi que se
comparan las dos partes sin tildes: el texto guardado y lo que se escribio.

Se usa translate() de PostgreSQL en vez de la extension unaccent porque
CREATE EXTENSION necesita permisos que en Cloud SQL no siempre estan, y no
vale la pena que el buscador dependa de eso.
"""

import unicodedata

from sqlalchemy import ColumnElement, func

# Las dos cadenas deben tener la misma cantidad de caracteres: translate()
# mapea posicion por posicion.
CON_TILDE = "áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ"
SIN_TILDE = "aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC"

assert len(CON_TILDE) == len(SIN_TILDE)


def normalizar(texto: str) -> str:
    """Version sin tildes y en minuscula de lo que escribio el usuario."""
    descompuesto = unicodedata.normalize("NFD", texto)
    plano = "".join(c for c in descompuesto if unicodedata.category(c) != "Mn")
    return plano.lower().strip()


def columna_plana(columna: ColumnElement) -> ColumnElement:
    """La misma normalizacion, pero calculada por PostgreSQL sobre la columna."""
    return func.lower(func.translate(columna, CON_TILDE, SIN_TILDE))


def patron(texto: str) -> str:
    """Lo que escribio el usuario, listo para un LIKE."""
    return f"%{normalizar(texto)}%"
