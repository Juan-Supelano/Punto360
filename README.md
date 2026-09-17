# Cuadre POS (Punto360)

Sistema de punto de venta (POS) para la gestión de productos, inventario, ventas, compras, clientes y proveedores, mediante una API REST y una interfaz web.

---

## Descripción

Cuadre POS es un sistema pensado para llevar el control completo del punto de venta de un negocio: desde el catálogo de productos hasta el registro de ventas, compras e inventario.

- **Qué es**: una aplicación web compuesta por una API (backend) y una interfaz de usuario (frontend) que permiten administrar el catálogo, las ventas, las compras, el inventario y los usuarios de un punto de venta.
- **Qué problema busca solucionar**: la necesidad de tener organizada y centralizada la información de productos, ventas, compras, clientes y proveedores, evitando duplicados, precios inválidos, datos inconsistentes o pérdida de control sobre el stock.
- **Enfoque**: cubre el flujo completo de un punto de venta: administrar el catálogo, cobrar, descontar inventario, emitir un comprobante y registrar quién hizo cada operación.
- **Para quién está pensado**: pequeños y medianos negocios que necesitan un punto de venta con control de inventario y usuarios, y también sirve como base de aprendizaje para quienes estén estudiando desarrollo de aplicaciones en la nube.

> Este proyecto nació como una actividad integradora de un curso de desarrollo de aplicaciones en la nube.

---

## Funcionalidades

### Catálogo

| Funcionalidad | ¿Qué le permite hacer al usuario? |
|---|---|
| **Gestión de categorías** | Crear, ver, actualizar y desactivar categorías para organizar los productos del negocio. |
| **Gestión de productos** | Crear, ver, actualizar y desactivar productos, asociando cada uno a una categoría. |
| **Búsqueda y filtrado de productos** | Buscar productos por nombre y filtrarlos por categoría, para encontrar rápidamente lo que se necesita. |
| **Desactivación en lugar de borrado** | Al "eliminar" un producto o categoría, este no se borra de la base de datos: se marca como inactivo, conservando el historial de información. |
| **Validaciones automáticas** | El sistema evita datos inconsistentes: no permite códigos de producto repetidos, nombres de categoría repetidos, precios menores o iguales a cero, ni asociar un producto a una categoría inexistente. |
| **Documentación interactiva de la API** | La API expone documentación automática (Swagger) donde se pueden probar todos los endpoints disponibles. |

### Ventas, compras e inventario

| Funcionalidad | ¿Qué le permite hacer al usuario? |
|---|---|
| **Registro de ventas** | Cobrar productos en el mostrador: elige productos y cantidades, calcula el total, descuenta el stock y registra la venta como una sola transacción (si algo falla, no se guarda nada a medias). |
| **Cálculo y desglose de IVA** | Cada venta y compra calcula automáticamente el subtotal, el IVA y el total por línea, soportando precios con IVA incluido o excluido, con redondeo comercial para que los valores siempre cuadren. |
| **Comprobante de venta imprimible** | Genera un recibo/ticket (pensado para impresora térmica de 80 mm) con los datos del comercio, el detalle de productos, impuestos y el vuelto, útil como comprobante para el cliente. |
| **Numeración de ventas** | Cada venta recibe automáticamente un número consecutivo de comprobante, generado por la base de datos. |
| **Anulación de ventas y compras** | Permite anular una venta o compra sin borrarla: el sistema devuelve el stock automáticamente y deja registrado el motivo de la anulación. |
| **Registro de compras a proveedores** | Registrar la entrada de mercancía asociada a un proveedor y a su número de factura, actualizando el stock y el costo del producto. |
| **Kardex de inventario** | Lleva un historial (movimiento por movimiento) de cada entrada, salida, venta, compra o anulación de stock, con el valor anterior y el resultante. |
| **Gestión de clientes y proveedores** | Registrar, buscar, editar y desactivar clientes y proveedores, con validación de documento/NIT único. |

### Usuarios y configuración del negocio

| Funcionalidad | ¿Qué le permite hacer al usuario? |
|---|---|
| **Autenticación y roles de usuario** | Inicio de sesión con usuario y contraseña (token JWT). Existen dos roles: **ADMIN** (gestiona el negocio, usuarios y compras) y **CAJERO** (solo puede registrar ventas). |
| **Gestión de usuarios** | El ADMIN puede crear, editar, desactivar y resetear la contraseña de otros usuarios del sistema. |
| **Perfil y datos del comercio** | Cada usuario puede editar su propio perfil (nombre, foto), y el ADMIN puede configurar los datos del negocio (razón social, NIT, logo, resolución) que aparecen en el comprobante de venta. |

---

## ¿Por qué utilizar este proyecto?

- **Organización de la información**: centraliza productos, categorías, clientes, proveedores y movimientos de inventario en una sola base de datos.
- **Reducción de errores**: las validaciones del backend evitan datos duplicados o inválidos, y el cálculo de IVA se hace de forma automática y consistente.
- **Conservación del historial**: al desactivar en lugar de borrar, y al anular en lugar de eliminar ventas o compras, no se pierde información previamente registrada.
- **Control de procesos**: el kardex de inventario permite rastrear cada movimiento de stock (venta, compra, anulación o ajuste) y quién lo generó.
- **Control de acceso**: el sistema de roles (ADMIN / CAJERO) delimita qué puede hacer cada tipo de usuario, dejando trazabilidad de quién registró cada venta.
- **Facilidad de uso**: cuenta con una interfaz web para gestionar todo el flujo del punto de venta, incluyendo un comprobante imprimible para el cliente.
- **Base lista para crecer**: su arquitectura (API + frontend separados) facilita agregar nuevos módulos en el futuro.

---

## Tecnologías utilizadas

### Backend

| Tecnología | Función en el proyecto |
|---|---|
| **Python** | Lenguaje principal del backend. |
| **FastAPI** | Framework para construir la API REST. |
| **Uvicorn** | Servidor que ejecuta la aplicación FastAPI. |
| **SQLAlchemy** | ORM para modelar y manejar las tablas de la base de datos. |
| **Psycopg** | Driver de conexión entre Python y PostgreSQL. |
| **Pydantic** | Define y valida los datos que entran y salen de la API. |
| **python-dotenv** | Carga la configuración desde el archivo `.env`. |
| **PyJWT** | Genera y valida los tokens de sesión (autenticación). |
| **bcrypt** | Genera el hash seguro de las contraseñas de los usuarios. |
| **python-multipart** | Permite recibir formularios y archivos en la API (por ejemplo, fotos de perfil o del negocio). |

### Frontend

| Tecnología | Función en el proyecto |
|---|---|
| **React** | Librería para construir la interfaz de usuario. |
| **Vite** | Herramienta de desarrollo y empaquetado del frontend. |

### Base de datos

| Tecnología | Función en el proyecto |
|---|---|
| **PostgreSQL** | Base de datos relacional donde se almacena toda la información del sistema (catálogo, ventas, compras, usuarios, kardex, etc.). |

---

## Arquitectura general

El proyecto está dividido en dos partes que se comunican entre sí:

- **Backend (API)**: expone rutas por módulo (`/productos`, `/categorias`, `/ventas`, `/compras`, `/clientes`, `/proveedores`, `/usuarios`, `/auth`, `/perfil`). Recibe peticiones, valida la información, aplica las reglas de negocio (por ejemplo, que no se venda más stock del disponible) y se comunica con la base de datos.
- **Frontend (interfaz web)**: pantallas construidas en React desde donde el usuario interactúa con el sistema: login, venta en mostrador, compras, clientes, proveedores, usuarios y un componente de recibo imprimible. Se comunica con el backend mediante peticiones HTTP.
- **Base de datos (PostgreSQL)**: almacena de forma persistente productos, categorías, ventas, compras, clientes, proveedores, usuarios y el kardex de movimientos de inventario.

Adicionalmente:

- Las peticiones a rutas protegidas requieren un **token de sesión (JWT)**, obtenido al iniciar sesión en `/auth/login`.
- La base de datos se administra con los scripts SQL de la carpeta `database/` (ver [Carpeta database](#carpeta-database)), en lugar de dejar que el backend cree las tablas automáticamente.
- Existe un **`Dockerfile`** para empaquetar el backend como contenedor, pensado para desplegarse en un servicio como Cloud Run.

El flujo general es: el usuario interactúa con el **frontend** → el frontend envía peticiones (con su token, si aplica) a la **API** → la API valida, aplica las reglas de negocio y consulta o modifica la **base de datos** → la respuesta regresa al frontend, que la muestra al usuario.

### Carpeta database

| Archivo | Contenido |
|---|---|
| `database/schema.sql` | Estructura de la base: las 12 tablas con sus llaves y restricciones. Se eliminó la versión anterior, que solo traía datos, y se reemplazó por esta con el mismo nombre. |
| `database/seed.sql` | Datos de ejemplo: comercio, usuarios, catálogo, clientes, proveedores, compras, ventas y kardex. |
| `database/diagram.png` | Diagrama entidad-relación de la base. |

Los scripts de migración sueltos que estaban en `backend/` (`migracion_*.sql` y `datos_compras.sql`) se eliminaron por obsoletos.

---

## Endpoints

Base local: `http://localhost:8000`. La documentación interactiva está en `/docs`.

- **Autenticación**: salvo `/`, `/salud` y `POST /auth/login`, todas las rutas piden el encabezado `Authorization: Bearer <access_token>`.
- **Contraseña temporal**: si un ADMIN reseteó la contraseña, el usuario recibe `403` en categorías, productos, proveedores, compras, clientes y ventas hasta cambiarla en `POST /perfil/cambiar-password`.
- **Rol**: *Sesión* = cualquier usuario autenticado; *ADMIN* o *CAJERO* = solo ese rol.

### Estado

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/` | Público | Nombre del servicio y estado |
| GET | `/salud` | Público | Health check (Cloud Run) |

### Autenticación — `/auth`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| POST | `/auth/login` | Público | Recibe `email` y `password`; devuelve `access_token`, `expira_en` (segundos) y el usuario |
| GET | `/auth/yo` | Sesión | Usuario dueño del token |
| GET | `/auth/comercio` | Sesión | Datos de la empresa |
| PUT | `/auth/comercio` | ADMIN | Actualiza los datos de la empresa |

### Perfil — `/perfil`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/perfil/yo` | Sesión | Perfil propio |
| PUT | `/perfil/yo` | Sesión | Cambia `nombre` y `foto_url` |
| POST | `/perfil/cambiar-password` | Sesión | Recibe `password_actual` y `password_nueva` (mínimo 8 caracteres) |

### Usuarios — `/usuarios`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/usuarios` | ADMIN | Lista. Query: `buscar`, `incluir_inactivos` |
| POST | `/usuarios` | ADMIN | Crea. Cuerpo: `email`, `nombre`, `password` (mínimo 8), `rol` |
| PUT | `/usuarios/{id}` | ADMIN | Cambia `nombre`, `rol` o `activo`. Nadie puede quitarse su propio rol ADMIN |
| DELETE | `/usuarios/{id}` | ADMIN | Desactiva. Nadie puede desactivar su propia cuenta |
| POST | `/usuarios/{id}/reactivar` | ADMIN | Reactiva |
| POST | `/usuarios/{id}/resetear-password` | ADMIN | Genera una contraseña temporal y la devuelve una sola vez |

### Categorías — `/categorias`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/categorias` | Sesión | Lista. Query: `incluir_inactivas` |
| GET | `/categorias/{id}` | Sesión | Una categoría |
| POST | `/categorias` | ADMIN | Crea. Cuerpo: `nombre`, `descripcion`, `prefijo_sku` (2 a 5 caracteres A-Z/0-9) |
| PUT | `/categorias/{id}` | ADMIN | Actualiza `nombre`, `descripcion`, `prefijo_sku` o `activo` |
| DELETE | `/categorias/{id}` | ADMIN | Desactiva. Devuelve `409` si tiene productos activos |
| POST | `/categorias/{id}/reactivar` | ADMIN | Reactiva |

### Productos — `/productos`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/productos` | Sesión | Lista. Query: `categoria_id`, `buscar`, `solo_stock_bajo`, `incluir_inactivos` |
| GET | `/productos/siguiente-sku?categoria_id=N` | Sesión | Vista previa del SKU que se asignaría (no lo reserva) |
| GET | `/productos/{id}` | Sesión | Un producto |
| POST | `/productos` | Sesión | Crea. El SKU lo genera el backend con el prefijo de la categoría (`BEB-001`, `BEB-002`…) |
| PUT | `/productos/{id}` | Sesión | Actualiza los campos enviados |
| PATCH | `/productos/{id}/stock?cantidad=N` | Sesión | Ajuste manual: `N` positivo suma, negativo resta. Queda en el kardex |
| DELETE | `/productos/{id}` | Sesión | Desactiva |
| POST | `/productos/{id}/reactivar` | Sesión | Reactiva |

Unidades de medida válidas: `UND`, `KG`, `LT`, `MT`, `CAJA`, `PAQ`.

### Clientes — `/clientes`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/clientes` | Sesión | Lista. Query: `buscar` (nombre o documento), `incluir_inactivos` |
| GET | `/clientes/{id}` | Sesión | Un cliente |
| POST | `/clientes` | Sesión | Crea. Cuerpo: `tipo_doc` (`CC`, `NIT`, `CE`, `TI`, `PAS`), `num_doc`, `nombre`, `email`, `telefono`, `direccion` |
| PUT | `/clientes/{id}` | Sesión | Actualiza `nombre`, `email`, `telefono`, `direccion` o `activo` |
| DELETE | `/clientes/{id}` | Sesión | Desactiva |
| POST | `/clientes/{id}/reactivar` | Sesión | Reactiva |

### Proveedores — `/proveedores`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/proveedores` | Sesión | Lista. Query: `buscar`, `incluir_inactivos` |
| GET | `/proveedores/{id}` | Sesión | Un proveedor |
| GET | `/proveedores/{id}/resumen` | Sesión | Número de compras, total comprado y fecha de la última compra |
| POST | `/proveedores` | ADMIN | Crea. El NIT debe ser único |
| PUT | `/proveedores/{id}` | ADMIN | Actualiza |
| DELETE | `/proveedores/{id}` | ADMIN | Desactiva |
| POST | `/proveedores/{id}/reactivar` | ADMIN | Reactiva |

### Compras — `/compras`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/compras` | Sesión | Lista. Query: `proveedor_id`, `estado` (`RECIBIDA`, `ANULADA`), `desde`, `hasta` |
| GET | `/compras/{id}` | Sesión | Compra con sus ítems |
| POST | `/compras` | ADMIN | Registra la compra en una transacción: suma stock y escribe el kardex |
| POST | `/compras/{id}/anular` | ADMIN | Anula y devuelve el stock. Cuerpo opcional: `motivo` |

Cuerpo de `POST /compras`:

```json
{
  "proveedor_id": 1,
  "numero_factura": "FV-1001",
  "costo_incluye_iva": false,
  "items": [{ "producto_id": 3, "cantidad": 10, "costo_unitario": 2500 }]
}
```

### Ventas — `/ventas`

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/ventas` | Sesión | Lista. Query: `usuario_id`, `estado` (`PAGADA`, `ANULADA`), `desde`, `hasta`. El CAJERO solo ve sus ventas |
| GET | `/ventas/resumen` | Sesión | Totales del periodo (`desde`, `hasta`). El CAJERO solo ve los suyos |
| GET | `/ventas/por-cajero` | ADMIN | Total vendido por cada cajero (`desde`, `hasta`) |
| GET | `/ventas/{id}` | Sesión | Venta con sus ítems. El CAJERO solo puede ver las suyas |
| POST | `/ventas` | CAJERO | Registra la venta en una transacción: congela precios, descuenta stock y escribe el kardex |
| POST | `/ventas/{id}/anular` | ADMIN | Anula y devuelve el stock. Cuerpo: `motivo` (3 a 200 caracteres) |

Cuerpo de `POST /ventas` (los precios los pone el backend):

```json
{
  "cliente_id": null,
  "metodo_pago": "EFECTIVO",
  "precio_incluye_iva": true,
  "observaciones": null,
  "items": [{ "producto_id": 3, "cantidad": 2 }]
}
```

Métodos de pago: `EFECTIVO`, `TARJETA`, `TRANSFERENCIA`, `MIXTO`.

### Archivos estáticos

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/static/...` | Archivos servidos desde `backend/static` (por ejemplo, fotos) |

### Códigos de error

| Código | Cuándo |
|---|---|
| 400 | Referencia inválida (categoría, proveedor o cliente inexistente o inactivo), unidad inválida, contraseña actual incorrecta, un ADMIN intentando desactivarse o quitarse el rol |
| 401 | Falta el token, token inválido o vencido, credenciales incorrectas |
| 403 | Rol sin permiso, usuario desactivado, contraseña temporal sin cambiar, venta de otro cajero |
| 404 | Recurso no encontrado |
| 409 | Dato repetido (nombre, prefijo, NIT, documento, correo), stock insuficiente, categoría con productos activos, venta o compra ya anulada |
| 422 | Cuerpo o parámetros con formato inválido |

---

## Escalabilidad

### Actualmente implementado

- Gestión completa de productos, categorías, clientes y proveedores.
- Registro de ventas y compras como transacciones completas, con actualización de inventario.
- Cálculo de IVA, comprobante de venta imprimible y kardex de movimientos.
- Autenticación con roles (ADMIN / CAJERO) y gestión de usuarios.
- `Dockerfile` listo para contenedorizar el backend.

### Posible crecimiento futuro

- **Nuevos usuarios**: el modelo de datos ya soporta varios usuarios por comercio con roles distintos, lo que facilita sumar más cajeros o administradores.
- **Nuevos módulos**: por ejemplo, manejo de caja (apertura y cierre de turno; ya existe un campo preparado para esto pero aún no se usa), reportes o devoluciones.
- **Nuevas funcionalidades**: facturación electrónica ante la DIAN (hoy solo existen campos como resolución y prefijo, pero no una integración real), pasarelas de pago, o notificaciones.
- **Mayor cantidad de información**: al usar PostgreSQL, el sistema puede escalar el volumen de datos sin cambiar de tecnología.
- **Versionado de la base de datos**: hoy se administra con scripts SQL manuales; podría formalizarse con una herramienta como Alembic.
- **Despliegue en la nube**: ya existe un `Dockerfile` para el backend; falta automatizar el despliegue completo (backend, frontend y base de datos) en un proveedor como Cloud Run.
- **Integraciones**: conexión con otras herramientas externas (contabilidad, pasarelas de pago, etc.) en etapas posteriores.

> Los puntos de "posible crecimiento futuro" son proyecciones y **no representan funcionalidades ya implementadas**.

---

## Limitaciones

- No existe una integración real de **facturación electrónica ante la DIAN**: solo hay campos preparados (prefijo de factura, resolución) para una futura integración.
- El manejo de **caja** (apertura y cierre de turno) todavía no está implementado; existe un campo de referencia en las ventas, pero no se usa aún.
- No incluye todavía versionado formal de base de datos (por ejemplo, Alembic); los cambios de esquema se administran con scripts SQL manuales.
- No cuenta con reportes, tableros de indicadores ni funcionalidad de devoluciones.
- No hay automatización de despliegue completo en la nube: existe un `Dockerfile` para el backend, pero falta una configuración lista para producción (frontend, base de datos, variables de entorno por entorno, etc.).
- Al ser un proyecto académico, no ha sido probado a fondo en un entorno de producción real con múltiples usuarios simultáneos.

---

## Próximas mejoras

- Integración real de **facturación electrónica** con la DIAN (hoy solo existen los campos base: resolución y prefijo de factura).
- Implementación del **manejo de caja** (apertura, cierre y cuadre de turno).
- Módulo de **reportes** (ventas por periodo, productos más vendidos, valorización de inventario, etc.).
- Módulo de **devoluciones** de productos.
- Integración de **Alembic** para el versionado de la base de datos.
- Automatización del despliegue completo (backend, frontend y base de datos) en **Cloud Run** u otro proveedor.

---

## Instalación y ejecución

### Requisitos previos

- Python 3.11 o superior
- Node.js 18 o superior
- PostgreSQL instalado y funcionando
- Git

### 1. Clonar el repositorio

```bash
git clone https://github.com/Juan-Supelano/Punto360.git
cd Punto360
```

### 2. Crear la base de datos y cargar el esquema

1. En pgAdmin (o el gestor de PostgreSQL que uses), crea una base de datos llamada `cuadre_pos`.
2. Carga la estructura de tablas ejecutando el script `database/schema.sql` sobre esa base de datos.
3. (Opcional) Ejecuta `database/seed.sql` para cargar datos de ejemplo.

### 3. Configurar las variables de entorno

**Backend:**

1. Copia `backend/.env.example` como `backend/.env`.
2. Reemplaza `TU_CONTRASENA` por la contraseña de tu usuario de PostgreSQL.

**Frontend:**

1. Copia `frontend/.env.example` como `frontend/.env`.
2. Por defecto apunta a `http://localhost:8000` (la API en local); solo debes cambiarlo si despliegas la API en otro lugar.

### 4. Ejecutar el backend (API)

En una terminal, dentro de la carpeta `backend`:

```bash
python -m venv .venv
.venv\Scripts\activate      # En Windows
# source .venv/bin/activate  # En macOS/Linux
pip install -r requirements.txt
uvicorn app.main:app --reload
```

La API quedará disponible en:
- Servicio: `http://localhost:8000`
- Documentación interactiva: `http://localhost:8000/docs`

### 5. Crear un usuario para iniciar sesión

Con el entorno virtual activado, dentro de `backend`:

```bash
python usuarios.py crear admin@cuadrepos.co "Nombre Apellido" MiClave123 ADMIN
```

También puedes listar los usuarios existentes con `python usuarios.py listar`.

### 6. Ejecutar el frontend

En **otra** terminal, dentro de la carpeta `frontend`:

```bash
npm install
npm run dev
```

La interfaz quedará disponible en `http://localhost:5173`. Inicia sesión con el usuario creado en el paso anterior.

> Backend y frontend deben ejecutarse al mismo tiempo, cada uno en su propia terminal.

---

## Estado del proyecto

**En desarrollo.**

Cuenta con un flujo funcional de punto de venta: catálogo, ventas, compras, inventario, clientes, proveedores y usuarios con autenticación. Aún no ha sido desplegado en un entorno de producción real ni probado con usuarios finales a gran escala.