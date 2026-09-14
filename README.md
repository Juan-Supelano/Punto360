# Cuadre POS (Punto360)

Sistema de punto de venta (POS) enfocado en la gestión de productos e inventario mediante una API REST y una interfaz web sencilla.

---

## Descripción

Cuadre POS es un sistema pensado para llevar el control de los productos y categorías que maneja un negocio dentro de un punto de venta.

- **Qué es**: una aplicación web compuesta por una API (backend) y una interfaz de usuario (frontend) que permiten administrar el catálogo de un punto de venta.
- **Qué problema busca solucionar**: la necesidad de tener organizada y centralizada la información de productos y categorías, evitando duplicados, precios inválidos o datos inconsistentes.
- **Enfoque**: parte desde una base sólida de gestión de catálogo (productos y categorías), con la intención de crecer hacia el registro de ventas.
- **Para quién está pensado**: pequeños y medianos negocios que necesitan un punto de venta simple, y también sirve como base de aprendizaje para quienes estén estudiando desarrollo de aplicaciones en la nube.

> Este proyecto nació como una actividad integradora de un curso de desarrollo de aplicaciones en la nube.

---

## Funcionalidades

| Funcionalidad | ¿Qué le permite hacer al usuario? |
|---|---|
| **Gestión de categorías** | Crear, ver, actualizar y desactivar categorías para organizar los productos del negocio. |
| **Gestión de productos** | Crear, ver, actualizar y desactivar productos, asociando cada uno a una categoría. |
| **Búsqueda y filtrado de productos** | Buscar productos por nombre y filtrarlos por categoría, para encontrar rápidamente lo que se necesita. |
| **Desactivación en lugar de borrado** | Al "eliminar" un producto o categoría, este no se borra de la base de datos: se marca como inactivo, conservando el historial de información. |
| **Validaciones automáticas** | El sistema evita datos inconsistentes: no permite códigos de producto repetidos, nombres de categoría repetidos, precios menores o iguales a cero, ni asociar un producto a una categoría inexistente. |
| **Documentación interactiva de la API** | La API expone documentación automática (Swagger) donde se pueden probar todos los endpoints disponibles. |

---

## ¿Por qué utilizar este proyecto?

- **Organización de la información**: centraliza productos y categorías en una sola base de datos, evitando hojas de cálculo dispersas.
- **Reducción de errores**: las validaciones del backend evitan datos duplicados o inválidos antes de que lleguen a la base de datos.
- **Conservación del historial**: al desactivar en lugar de borrar, no se pierde información previamente registrada.
- **Facilidad de uso**: cuenta con una interfaz web simple para gestionar productos y categorías sin necesidad de conocimientos técnicos.
- **Base lista para crecer**: su arquitectura (API + frontend separados) facilita agregar nuevos módulos en el futuro, como el de ventas.

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

### Frontend

| Tecnología | Función en el proyecto |
|---|---|
| **React** | Librería para construir la interfaz de usuario. |
| **Vite** | Herramienta de desarrollo y empaquetado del frontend. |

### Base de datos

| Tecnología | Función en el proyecto |
|---|---|
| **PostgreSQL** | Base de datos relacional donde se almacenan productos y categorías. |

---

## Arquitectura general

El proyecto está dividido en dos partes que se comunican entre sí:

- **Backend (API)**: expone rutas (`/productos`, `/categorias`) que reciben peticiones, validan la información y se comunican con la base de datos. Es el encargado de aplicar las reglas de negocio (por ejemplo, que no existan códigos de producto duplicados).
- **Frontend (interfaz web)**: pantallas construidas en React desde donde el usuario interactúa con productos y categorías. Se comunica con el backend a través de peticiones HTTP hacia la API.
- **Base de datos (PostgreSQL)**: almacena de forma persistente la información de productos y categorías.

El flujo general es: el usuario interactúa con el **frontend** → el frontend envía peticiones a la **API** → la API valida y consulta o modifica la **base de datos** → la respuesta regresa al frontend, que la muestra al usuario.

---

## Escalabilidad

### Actualmente implementado

- Gestión completa (crear, leer, actualizar, desactivar) de productos y categorías.
- Validaciones básicas de integridad de datos.

### Posible crecimiento futuro

- **Nuevos módulos**: incorporación de ventas y detalle de venta, para registrar transacciones completas del punto de venta.
- **Nuevas funcionalidades**: reportes de inventario, historial de movimientos, control de usuarios y roles.
- **Mayor cantidad de información**: el uso de PostgreSQL como base de datos relacional permite escalar el volumen de datos sin cambiar de tecnología.
- **Versionado de la base de datos**: adopción de Alembic para gestionar cambios en el esquema de forma controlada.
- **Despliegue en la nube**: contenedorización con Docker y despliegue en servicios como Cloud Run, permitiendo que más usuarios accedan al sistema simultáneamente.
- **Integraciones**: posibilidad de conectar el sistema con otras herramientas (facturación electrónica, pasarelas de pago, etc.) en etapas posteriores.

> Estos puntos son proyecciones de crecimiento y **no representan funcionalidades ya implementadas**.

---

## Limitaciones

- Aún no existe un módulo de ventas: el sistema solo gestiona catálogo (productos y categorías), no transacciones.
- No cuenta con manejo de usuarios, autenticación ni control de roles.
- No incluye todavía versionado de base de datos (Alembic), por lo que los cambios de esquema deben manejarse manualmente.
- No existe configuración de despliegue en la nube (Docker, Cloud Run) en la versión actual.
- Al ser un proyecto académico en desarrollo, no ha sido probado en un entorno de producción real.

---

## Próximas mejoras

- Implementación de las entidades **venta** y **venta_item**, permitiendo registrar una venta como una sola transacción.
- Integración de **Alembic** para el versionado de la base de datos.
- Creación de **Dockerfile** y despliegue en **Cloud Run**.

---

## Instalación y ejecución

### Requisitos previos

- Python 3.11 o superior
- Node.js 18 o superior
- PostgreSQL instalado y funcionando

### 1. Crear la base de datos

En pgAdmin (o el gestor de PostgreSQL que uses):

1. Clic derecho sobre **Databases → Create → Database…**
2. Asignar el nombre `cuadre_pos` y guardar.

### 2. Configurar las variables de entorno

1. Abrir el archivo `backend/.env`.
2. Reemplazar `TU_CONTRASENA` por la contraseña configurada al instalar PostgreSQL.

### 3. Ejecutar el backend (API)

En una terminal, dentro de la carpeta `backend`:

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python seed.py
uvicorn app.main:app --reload
```

La API quedará disponible en:
- Servicio: `http://localhost:8000`
- Documentación interactiva: `http://localhost:8000/docs`

### 4. Ejecutar el frontend

En **otra** terminal, dentro de la carpeta `frontend`:

```powershell
npm install
npm run dev
```

La interfaz quedará disponible en `http://localhost:5173`.

> Ambas terminales deben permanecer abiertas mientras se trabaja en el proyecto. Los cambios en los archivos se recargan automáticamente.

---

## Estado del proyecto

**En desarrollo.**

Actualmente cuenta con la gestión funcional de productos y categorías. El módulo de ventas y las mejoras de despliegue en la nube están planificadas para etapas posteriores.
