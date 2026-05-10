from datetime import datetime, UTC
import os
import socket

from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="Zero-Downtime Traffic Shifter")

APP_VERSION = os.getenv("APP_VERSION", "dev")
APP_COLOR = os.getenv("APP_COLOR", "blue")
HOSTNAME = socket.gethostname()
STARTED_AT = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


@app.get("/")
def root():
    payload = {
        "message": "hello",
        "version": APP_VERSION,
        "color": APP_COLOR,
        "hostname": HOSTNAME,
        "started_at": STARTED_AT,
    }
    headers = {
        "X-App-Color": APP_COLOR,
        "X-App-Version": APP_VERSION,
    }
    return JSONResponse(content=payload, headers=headers)


@app.get("/health")
def health():
    return {"status": "ok"}
