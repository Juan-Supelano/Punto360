# img — imágenes de marca Punto360

Carpeta única y plana. Al vivir dentro de `public/`, Vite la copia tal cual a
la raíz del build (`dist/img/...`), así que las rutas funcionan igual en
desarrollo y en producción (GCP), sin depender de imports ni de dónde quede
desplegado el `dist/`.

Archivos esperados (nombre exacto):

| Archivo                  | Dónde se usa                                    | Ruta con la que se referencia   |
| ------------------------ | ------------------------------------------------ | -------------------------------- |
| `logo-punto360.png`      | Login — `src/pages/Login.jsx` (antes decía "CP")  | `/img/logo-punto360.png`         |
| `isotipo-punto360.png`   | Login — `src/pages/Login.jsx` (antes "Cuadre POS")| `/img/isotipo-punto360.png`      |
| `icon-punto360.png`      | `index.html` — ícono de la pestaña del navegador  | `/img/icon-punto360.png`         |

`icon-punto360.png` ya está puesto. Falta agregar `logo-punto360.png` y
`isotipo-punto360.png` (de preferencia con fondo transparente).
