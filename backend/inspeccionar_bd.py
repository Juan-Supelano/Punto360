"""Vuelca el esquema real de la base de datos a esquema.txt.

Uso (desde cuadre-pos\\backend, con el venv activado):
    python inspeccionar_bd.py
"""

from sqlalchemy import inspect, text

from app.database import engine

lineas = []


def w(s=""):
    lineas.append(s)


insp = inspect(engine)

with engine.connect() as con:
    bd = con.execute(text("select current_database()")).scalar()
    esquemas = [r[0] for r in con.execute(text(
        "select schema_name from information_schema.schemata "
        "where schema_name not in ('pg_catalog','information_schema') "
        "order by schema_name"
    ))]
    search_path = con.execute(text("show search_path")).scalar()

w(f"BASE DE DATOS: {bd}")
w(f"SEARCH_PATH  : {search_path}")
w(f"ESQUEMAS     : {', '.join(esquemas)}")
w()

for esquema in esquemas:
    tablas = insp.get_table_names(schema=esquema)
    if not tablas:
        continue
    w(f"########## ESQUEMA {esquema} ##########")
    for tabla in sorted(tablas):
        with engine.connect() as con:
            filas = con.execute(
                text(f'select count(*) from "{esquema}"."{tabla}"')
            ).scalar()
        w()
        w(f"===== {tabla}  ({filas} filas) =====")

        for col in insp.get_columns(tabla, schema=esquema):
            nulo = "NULL" if col["nullable"] else "NOT NULL"
            por_defecto = col.get("default")
            extra = f"  default={por_defecto}" if por_defecto else ""
            w(f"  {col['name']:<28} {str(col['type']):<28} {nulo}{extra}")

        pk = insp.get_pk_constraint(tabla, schema=esquema)
        if pk and pk.get("constrained_columns"):
            w(f"  PK: {', '.join(pk['constrained_columns'])}")

        for fk in insp.get_foreign_keys(tabla, schema=esquema):
            w(
                f"  FK: {', '.join(fk['constrained_columns'])} -> "
                f"{fk['referred_table']}.{', '.join(fk['referred_columns'])}"
            )

        for uq in insp.get_unique_constraints(tabla, schema=esquema):
            w(f"  UNIQUE: {', '.join(uq['column_names'])}")

        for ck in insp.get_check_constraints(tabla, schema=esquema):
            w(f"  CHECK: {ck.get('sqltext')}")

        for ix in insp.get_indexes(tabla, schema=esquema):
            w(f"  INDEX: {ix['name']} ({', '.join(c or '?' for c in ix['column_names'])})")

    vistas = insp.get_view_names(schema=esquema)
    if vistas:
        w()
        w(f"VISTAS en {esquema}: {', '.join(vistas)}")
    w()

salida = "\n".join(lineas)
with open("esquema.txt", "w", encoding="utf-8") as f:
    f.write(salida)

print(salida)
print()
print("--> Escrito en esquema.txt")
