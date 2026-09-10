from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Lee la configuracion desde el archivo .env."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = (
        "postgresql+psycopg://postgres:postgres@localhost:5432/proyecto_nube"
    )

    # --- Autenticacion -------------------------------------------------------
    # En la nube este valor sale de Secret Manager, nunca del repositorio.
    jwt_secreto: str = "cambiar-esto-en-produccion"
    jwt_algoritmo: str = "HS256"
    jwt_minutos: int = 480  # 8 horas: un turno de caja

    # --- CORS ----------------------------------------------------------------
    # Lista separada por comas. Al desplegar se agrega la URL del frontend.
    cors_origenes: str = "http://localhost:5173,http://127.0.0.1:5173"

    @property
    def lista_cors(self) -> list[str]:
        return [o.strip() for o in self.cors_origenes.split(",") if o.strip()]


settings = Settings()
