# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.metrics.router import router as metrics_router
from app.reports.router import router as reports_router
from app.scheduler.tasks import start_scheduler
import uvicorn
import os

app = FastAPI(
    title="YoUSAC Analytics Service",
    description="Microservicio de Analítica - Métricas y Reportes",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(metrics_router, prefix="/api/analytics/metrics", tags=["Metrics"])
app.include_router(reports_router, prefix="/api/analytics/reports", tags=["Reports"])

@app.get("/health")
def health():
    return {"status": "ok", "service": "analytics"}

@app.on_event("startup")
async def startup_event():
    # Crear tablas solo si la BD está disponible, sin bloquear el arranque
    try:
        from app.database import engine, Base
        Base.metadata.create_all(bind=engine)
        print("✅ Tablas verificadas en MySQL")
    except Exception as e:
        print(f"⚠️  MySQL no disponible al arrancar: {e}")
        print("   El servicio continuará sin BD hasta que esté disponible")

    try:
        start_scheduler()
        print("✅ Analytics service iniciado")
    except Exception as e:
        print(f"⚠️  Error iniciando scheduler: {e}")

if __name__ == "__main__":
    port = int(os.getenv("HTTP_PORT", 3002))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=False)