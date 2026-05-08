from datetime import datetime
import os
import socket

from fastapi import FastAPI

app = FastAPI(title="Zero-Downtime Traffic Shifter")

APP_VERSION = os.getenv("APP_VERSION", "dev")
APP_COLOR = os.getenv("APP_COLOR", "blue")
HOSTNAME = socket.gethostname()
STARTED_AT = datetime.utcnow().isoformat() + "Z"


@app.get("/")
def root():
    return {
        "message": "hello",
        "version": APP_VERSION,
        "color": APP_COLOR,
        "hostname": HOSTNAME,
        "started_at": STARTED_AT,
    }


@app.get("/health")
def health():
    return {"status": "ok"}
