"""Carga unos datos de ejemplo para ver la aplicacion funcionando.

Uso:  python seed.py
"""

from decimal import Decimal

from app.database import Base, SessionLocal, engine
from app.models import Categoria, Producto

Base.metadata.create_all(bind=engine)

db = SessionLocal()

if db.query(Categoria).count() > 0:
    print("La base ya tiene datos. No se hizo nada.")
else:
    bebidas = Categoria(nombre="Bebidas", descripcion="Frias y calientes")
    panaderia = Categoria(nombre="Panaderia", descripcion="Producto de horno")
    aseo = Categoria(nombre="Aseo", descripcion="Limpieza del hogar")
    db.add_all([bebidas, panaderia, aseo])
    db.flush()

    db.add_all(
        [
            Producto(codigo="BEB-001", nombre="Cafe negro", precio_venta=Decimal("2500"),
                     stock=100, categoria_id=bebidas.id),
            Producto(codigo="BEB-002", nombre="Gaseosa 400ml", precio_venta=Decimal("3200"),
                     stock=48, categoria_id=bebidas.id),
            Producto(codigo="PAN-001", nombre="Pan aliñado", precio_venta=Decimal("1200"),
                     stock=60, categoria_id=panaderia.id),
            Producto(codigo="ASE-001", nombre="Jabon en barra", precio_venta=Decimal("4800"),
                     stock=25, categoria_id=aseo.id),
        ]
    )
    db.commit()
    print("Datos de ejemplo cargados.")

db.close()
