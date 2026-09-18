FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# psycopg[binary] y bcrypt traen ruedas precompiladas: no hace falta compilador.
# Quitar build-essential baja el build de varios minutos a menos de uno.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# main.py crea static/fotos al arrancar, pero el contenedor de Cloud Run es
# efimero: lo que se escriba ahi se pierde en el siguiente despliegue. Las
# fotos nuevas van a Cloud Storage y en la base solo queda la URL.
RUN mkdir -p /app/static/fotos

# Cloud Run inyecta PORT (8080 por defecto) y espera que el contenedor escuche ahi.
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
