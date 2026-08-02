from fastapi import FastAPI
import os

app = FastAPI(title="YoUSAC Analytics Service")

@app.get("/health")
def health():
    return {"status": "ok", "service": "analytics"}

# TODO: agregar routers de metrics y reports
