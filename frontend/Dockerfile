# --- Etapa 1: compilar el bundle de Vite -------------------------------------
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Vite incrusta VITE_API_URL en el bundle EN TIEMPO DE BUILD, no de ejecucion.
# El valor sale de .env.production, que se crea con la URL real del backend
# despues de desplegar Cloud Run. Cambiar la URL obliga a reconstruir la imagen.
RUN npm run build

# --- Etapa 2: servir los archivos estaticos ----------------------------------
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
