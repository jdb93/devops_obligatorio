import os
from urllib.parse import urlparse
import pg8000.native


def lambda_handler(event, context):
    # Obtenemos DATABASE_URL de las variables de entorno
    db_url = os.environ.get("DATABASE_URL")

    if not db_url:
        return {
            "status": "error",
            "message": "DATABASE_URL not found"
        }

    try:
        # Parseamos la URL de conexión estilo psycopg
        url = urlparse(db_url)

        user = url.username
        password = url.password
        host = url.hostname
        port = url.port
        database = url.path.lstrip("/")

        # Conectamos a la DB usando pg8000.native.Connection
        conn = pg8000.native.Connection(
            user=user,
            password=password,
            host=host,
            port=port,
            database=database,
        )

        # Leemos init.sql desde /var/task (directorio del ZIP)
        script_path = "/var/task/init.sql"
        with open(script_path, "r", encoding="utf-8") as f:
            sql = f.read()

        # Ejecutamos todo el SQL
        conn.run(sql)

        return {
            "status": "ok",
            "message": "Database initialized successfully"
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }
