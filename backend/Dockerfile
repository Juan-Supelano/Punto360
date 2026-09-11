FROM python:3.12-slim

WORKDIR /app

# Dependencias del sistema para compilar libs nativas si hiciera falta
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Cloud Run inyecta PORT (por defecto 8080) y espera que el contenedor escuche ahi
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
