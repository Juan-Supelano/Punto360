# Cuadre POS

Actividad integradora — Desarrollo de aplicaciones en la nube.
API REST en FastAPI + frontend en React, con PostgreSQL.

```
cuadre-pos/
├── backend/          la API (Python)
│   ├── app/
│   │   ├── main.py       arranque de la aplicación
│   │   ├── config.py     lee el archivo .env
│   │   ├── database.py   conexión a PostgreSQL
│   │   ├── models/       las tablas
│   │   ├── schemas/      qué entra y qué sale de la API
│   │   └── routers/      las rutas (/productos, /categorias)
│   ├── seed.py       carga datos de ejemplo
│   └── requirements.txt
└── frontend/         las pantallas (React)
    └── src/
        ├── api.js        único sitio donde vive la dirección de la API
        └── pages/        Productos.jsx y Categorias.jsx
```

---

## 1. Crear la base de datos

En pgAdmin: clic derecho sobre **Databases → Create → Database…**
Nombre: `cuadre_pos`. Guardar.

## 2. Poner la contraseña

Abrir `backend/.env` y reemplazar `TU_CONTRASENA` por la contraseña que pusiste
al instalar PostgreSQL.

## 3. Encender la API

Necesitas Python 3.11 o superior y Node 18 o superior.
En una terminal (PowerShell), dentro de `backend`:

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python seed.py
uvicorn app.main:app --reload
```

Queda corriendo en http://localhost:8000
La documentación automática está en http://localhost:8000/docs

## 4. Encender el frontend

En **otra** terminal, dentro de `frontend`:

```powershell
npm install
npm run dev
```

Queda corriendo en http://localhost:5173

Las dos terminales se quedan abiertas mientras trabajas. Cada vez que guardes
un archivo, se recargan solas.

---

## Qué hay hecho

- Entidades `categoria` y `producto`, relacionadas. CRUD completo en las dos.
- Nada se borra: el botón "Desactivar" marca `activo = false`.
- Validaciones: código de producto único, nombre de categoría único,
  precio mayor que cero, la categoría debe existir.

## Qué sigue

- Entidades `venta` y `venta_item` (la venta como una sola transacción).
- Alembic para versionar los cambios de la base.
- Dockerfile y despliegue en Cloud Run.
