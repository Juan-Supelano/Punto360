"""OBSOLETO — ya no se usa.

Este script cargaba datos de ejemplo cuando el backend creaba sus propias
tablas. Ahora el esquema y los datos de proyecto_nube los administra el equipo
con scripts SQL, y el backend solo se conecta a lo que ya existe.

En su lugar:
  - Estructura y datos de la empresa:  migracion_comercio.sql (en pgAdmin)
  - Usuarios y contrasenas:            python usuarios.py listar
  - Radiografia del esquema actual:    python inspeccionar_bd.py
"""

print(__doc__)
