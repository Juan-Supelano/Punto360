# Despliegue en GCP — Cuadre POS

Arquitectura final: dos servicios de Cloud Run (API y web) contra una instancia de
Cloud SQL PostgreSQL, con los secretos en Secret Manager y las imágenes en
Artifact Registry. Región `us-central1`.

```
navegador ──> cuadre-pos-web (nginx + build de Vite)   Cloud Run
                  │ fetch a VITE_API_URL
                  ▼
             cuadre-pos-api (FastAPI + uvicorn)        Cloud Run
                  │ socket /cloudsql/…
                  ▼
             proyecto_nube                             Cloud SQL PostgreSQL 16
```

Orden obligado: **base de datos → backend → frontend → CORS**. El frontend necesita
la URL del backend para compilarse y el backend necesita la URL del frontend para
autorizar CORS, así que el último paso es una actualización de variable de entorno.

---

## 0. Antes de empezar

Instalar el SDK de Google Cloud (`https://cloud.google.com/sdk/docs/install`) y en
PowerShell:

```powershell
gcloud auth login
gcloud config set project ID_DEL_PROYECTO
gcloud config set run/region us-central1

gcloud services enable `
  run.googleapis.com `
  cloudbuild.googleapis.com `
  artifactregistry.googleapis.com `
  sqladmin.googleapis.com `
  secretmanager.googleapis.com
```

Variables que se repiten en todo el documento (ajustar la primera y la tercera):

```powershell
$PROYECTO  = "ID_DEL_PROYECTO"
$REGION    = "us-central1"
$INSTANCIA = "NOMBRE_DE_TU_INSTANCIA_CLOUD_SQL"
$NUMERO    = gcloud projects describe $PROYECTO --format="value(projectNumber)"
$SA        = "$NUMERO-compute@developer.gserviceaccount.com"
$CONN      = gcloud sql instances describe $INSTANCIA --format="value(connectionName)"
$REPO      = "$REGION-docker.pkg.dev/$PROYECTO/cuadre-pos"
```

`$CONN` queda como `proyecto:us-central1:instancia`. Es el identificador que Cloud Run
usa para abrir el socket a Cloud SQL.

---

## 1. Actualizar la base de datos que ya está en Cloud SQL

El modelo cambió (`prefijo_sku`, las columnas de `configuracion_comercio`, el IVA, el
perfil) y los datos de ejemplo también. Aplicar migración por migración contra la nube
es lo que ya falló una vez: `migracion_sku.sql` quedó a medias y `GET /productos`
respondió 500. Con datos de prueba, **reemplazar la base entera desde el volcado local
es más seguro que parchearla**.

### 1.1 Volcar la base local

```powershell
cd $HOME\Documents\cuadre-pos
& "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" `
  -U postgres -h localhost -d proyecto_nube `
  --no-owner --no-privileges --clean --if-exists `
  -f proyecto_nube.sql
```

`--no-owner --no-privileges` evita que el volcado intente asignar roles que en Cloud SQL
no existen. `--clean --if-exists` hace que el archivo borre lo viejo antes de recrearlo,
así que se puede importar sobre la base actual sin vaciarla a mano.

Revisar que el archivo terminó completo: la última línea debe ser un comando SQL, no un
corte a mitad.

### 1.2 Cargarlo en Cloud SQL

Si la instancia tiene IP pública y ya te conectas desde pgAdmin, es directo:

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" `
  -h IP_PUBLICA_DE_LA_INSTANCIA -U postgres -d proyecto_nube `
  -v ON_ERROR_STOP=1 -f proyecto_nube.sql
```

`ON_ERROR_STOP=1` es importante: sin eso psql sigue tras el primer error y deja la base
en un estado intermedio, que es exactamente el problema del 11-sep.

Si tu IP cambió, autorízala antes:

```powershell
gcloud sql instances patch $INSTANCIA --authorized-networks=TU_IP/32
```

Alternativa sin abrir la IP pública (Cloud SQL Auth Proxy, deja la base escuchando en
`localhost:5433` mientras la ventana esté abierta):

```powershell
gcloud components install cloud-sql-proxy
cloud-sql-proxy $CONN --port 5433
```

### 1.3 Verificar

```sql
SELECT COUNT(*) FROM producto;
SELECT COUNT(*) FROM categoria WHERE prefijo_sku IS NULL;  -- debe dar 0
SELECT last_value FROM venta_numero_seq;
```

### 1.4 Usuario de aplicación

El backend no debería conectarse como `postgres`. Si no existe todavía:

```sql
CREATE USER app_pos WITH PASSWORD 'una-clave-larga';
GRANT CONNECT ON DATABASE proyecto_nube TO app_pos;
GRANT USAGE ON SCHEMA public TO app_pos;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_pos;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_pos;
```

Sin el `GRANT` sobre las secuencias, crear una venta falla: `venta.numero` sale de
`venta_numero_seq`.

---

## 2. Secretos

La cadena de conexión desde Cloud Run **no lleva host ni puerto**: va por socket Unix.

```
postgresql+psycopg://app_pos:CLAVE@/proyecto_nube?host=/cloudsql/PROYECTO:REGION:INSTANCIA
```

Si la clave tiene `@`, `:`, `/` o `#`, hay que codificarla en porcentaje o cambiarla por
una alfanumérica. Es una fuente clásica de fallos de conexión difíciles de leer.

```powershell
# Archivo temporal para no pelear con la codificación de PowerShell en el pipe
$url = "postgresql+psycopg://app_pos:CLAVE@/proyecto_nube?host=/cloudsql/$CONN"
[IO.File]::WriteAllText("$env:TEMP\dburl.txt", $url)
gcloud secrets create DATABASE_URL --data-file="$env:TEMP\dburl.txt"

$jwt = python -c "import secrets; print(secrets.token_urlsafe(48))"
[IO.File]::WriteAllText("$env:TEMP\jwt.txt", $jwt)
gcloud secrets create JWT_SECRETO --data-file="$env:TEMP\jwt.txt"

Remove-Item "$env:TEMP\dburl.txt","$env:TEMP\jwt.txt"
```

Permisos de la cuenta de servicio que ejecuta Cloud Run:

```powershell
gcloud secrets add-iam-policy-binding DATABASE_URL `
  --member="serviceAccount:$SA" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding JWT_SECRETO `
  --member="serviceAccount:$SA" --role="roles/secretmanager.secretAccessor"
gcloud projects add-iam-policy-binding $PROYECTO `
  --member="serviceAccount:$SA" --role="roles/cloudsql.client"
```

Para actualizar un secreto más adelante se agrega una versión, no se edita:
`gcloud secrets versions add JWT_SECRETO --data-file=...`.

---

## 3. Artifact Registry

```powershell
gcloud artifacts repositories create cuadre-pos `
  --repository-format=docker --location=$REGION `
  --description="Imagenes de Cuadre POS"
```

---

## 4. Backend en Cloud Run

```powershell
cd $HOME\Documents\cuadre-pos\backend
gcloud builds submit --tag "$REPO/backend:v1"

gcloud run deploy cuadre-pos-api `
  --image "$REPO/backend:v1" `
  --region $REGION `
  --allow-unauthenticated `
  --add-cloudsql-instances $CONN `
  --set-secrets "DATABASE_URL=DATABASE_URL:latest,JWT_SECRETO=JWT_SECRETO:latest" `
  --set-env-vars "CORS_ORIGENES=http://localhost:5173" `
  --memory 512Mi --cpu 1 --min-instances 0 --max-instances 3 --timeout 60
```

`pydantic-settings` lee las variables sin distinguir mayúsculas, así que `DATABASE_URL`,
`JWT_SECRETO` y `CORS_ORIGENES` caen directamente en los campos de `Settings`. El `.env`
no se copia a la imagen y no hace falta.

Guardar la URL que imprime el comando:

```powershell
$API = gcloud run services describe cuadre-pos-api --region $REGION --format="value(status.url)"
$API
```

Comprobar antes de seguir:

```powershell
curl "$API/salud"          # {"estado":"ok"}
start "$API/docs"
```

`/salud` responde sin tocar la base. Si `/salud` funciona pero `/productos` da 500, el
problema es la conexión a Cloud SQL o los permisos del usuario, no el contenedor:

```powershell
gcloud run services logs read cuadre-pos-api --region $REGION --limit 50
```

---

## 5. Frontend en Cloud Run

Vite incrusta `VITE_API_URL` durante `npm run build`. No es una variable de ejecución:
cambiar la URL de la API obliga a reconstruir la imagen.

```powershell
cd ..\frontend
[IO.File]::WriteAllText("$PWD\.env.production", "VITE_API_URL=$API`n")

gcloud builds submit --tag "$REPO/frontend:v1"

gcloud run deploy cuadre-pos-web `
  --image "$REPO/frontend:v1" `
  --region $REGION `
  --allow-unauthenticated `
  --port 8080 `
  --memory 256Mi --cpu 1 --min-instances 0 --max-instances 3

$WEB = gcloud run services describe cuadre-pos-web --region $REGION --format="value(status.url)"
$WEB
```

`.env.production` contiene una URL pública, no un secreto, así que puede ir al
repositorio. Revisar que el `.gitignore` no esté ignorando `.env*` completo.

---

## 6. Cerrar el círculo: CORS

Hasta aquí el navegador bloquea toda llamada del frontend a la API.

```powershell
gcloud run services update cuadre-pos-api `
  --region $REGION `
  --update-env-vars "CORS_ORIGENES=$WEB,http://localhost:5173"
```

Dejar `localhost:5173` permite seguir desarrollando contra la API de la nube. Para la
entrega conviene quitarlo.

---

## 7. Verificación final

1. Abrir `$WEB` y entrar con un usuario ADMIN.
2. Crear una categoría con prefijo y un producto: valida SKU automático y escritura.
3. Registrar una compra: valida transacción, stock y kardex.
4. Entrar como CAJERO y hacer una venta: valida secuencia de factura y roles.
5. Anular esa venta: valida la reversa de stock.
6. Con F12 abierto, confirmar que no aparecen errores de CORS.

---

## 8. Costo

Cloud SQL es lo único que cobra de forma continua (~9-11 USD/mes en `db-f1-micro`).
Cloud Run con `min-instances 0` no cobra mientras nadie entre.

```powershell
# Presupuesto y alerta: Facturación → Presupuestos y alertas → 10 USD, avisos al 50/90/100%

# Apagar la instancia fuera de horario
gcloud sql instances patch $INSTANCIA --activation-policy NEVER
gcloud sql instances patch $INSTANCIA --activation-policy ALWAYS
```

Con la instancia apagada, la API responde 500 en todo lo que toque la base. Encenderla
tarda un par de minutos: no dejarlo para el momento de la sustentación.

---

## 9. Qué queda pendiente después de esto

- **Alembic.** Ya van cinco migraciones a mano. Mientras el despliegue sea
  volcar-y-restaurar funciona; en cuanto haya datos que conservar, deja de funcionar.
- **Logos y fotos.** `almacenamiento.py` guarda URLs, pero lo que quede en
  `/app/static/fotos` dentro del contenedor se pierde en cada despliegue. Falta el
  bucket de Cloud Storage y subir ahí.
- **Colección de Postman.** Se arma importando `$API/openapi.json`.
- **Pantalla de kardex y `caja_sesion`**, del documento de pendientes.
