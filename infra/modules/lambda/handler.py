import json
import psycopg2
import os

def lambda_handler(event, context):
    try:
        db_url = os.getenv("DATABASE_URL")
        if not db_url:
            return {"status": "ERROR", "message": "Missing DATABASE_URL env var"}

        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        # Read SQL file
        with open("/var/task/init.sql", "r") as f:
            sql = f.read()

        cur.execute(sql)
        conn.commit()

        cur.close()
        conn.close()
        return {"status": "OK", "message": "Database initialized successfully"}
    except Exception as e:
        return {"status": "ERROR", "message": str(e)}
