from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

# El "engine" es la conexion viva con PostgreSQL.
engine = create_engine(settings.database_url, echo=False, pool_pre_ping=True)

# Cada peticion HTTP abre una sesion y la cierra al terminar.
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    """Clase de la que heredan todas las tablas."""


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
