import os


class Config:
    """
    All settings come from environment variables so this app can be
    containerized later without touching code — just pass different
    env vars (or an env_file) to `docker run` / docker-compose.
    """

    # --- Flask ---
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-change-me")
    DEBUG = os.environ.get("FLASK_DEBUG", "1") == "1"
    PORT = int(os.environ.get("PORT", "5000"))

    # --- MySQL ---
    DB_HOST = os.environ.get("DB_HOST", "localhost")
    DB_PORT = int(os.environ.get("DB_PORT", "3306"))
    DB_USER = os.environ.get("DB_USER", "root")
    DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
    DB_NAME = os.environ.get("DB_NAME", "lms_db")

    # --- Time tracking ---
    # How many seconds of "active tab" time the frontend reports per heartbeat.
    HEARTBEAT_INTERVAL_SECONDS = int(os.environ.get("HEARTBEAT_INTERVAL_SECONDS", "30"))
