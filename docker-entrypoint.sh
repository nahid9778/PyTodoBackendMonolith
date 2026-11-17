#!/bin/sh
set -eu

python - <<'PY'
import os
import time

import pyodbc

connection_string = os.environ.get("CONNECTION_STRING")
if not connection_string:
    raise SystemExit("CONNECTION_STRING is not set")

master = connection_string.replace("Database=todoapp", "Database=master")
last_error = "database connection failed"
for _ in range(40):
    try:
        conn = pyodbc.connect(master, autocommit=True)
        cursor = conn.cursor()
        cursor.execute("IF DB_ID(N'todoapp') IS NULL CREATE DATABASE todoapp")
        conn.close()
        break
    except Exception as exc:
        message = str(exc)
        if "Pwd=" in message or "PWD=" in message or "Uid=" in message:
            message = "database connection failed"
        last_error = message
        time.sleep(3)
else:
    raise SystemExit(last_error)
PY

exec uvicorn app:app --host 0.0.0.0 --port 8000
