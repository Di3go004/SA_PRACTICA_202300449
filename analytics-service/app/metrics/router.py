# app/metrics/router.py
# Principio S: solo maneja rutas de métricas
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.metrics.service import MetricsService

router = APIRouter()

def get_service(db: Session = Depends(get_db)) -> MetricsService:
    return MetricsService(db)

# GET /api/analytics/metrics/video/{video_id}
@router.get("/video/{video_id}")
def get_video_metrics(video_id: int, service: MetricsService = Depends(get_service)):
    """Retorna métricas de un video específico (RF-024, RF-035)"""
    metrics = service.get_video_metrics(video_id)
    if not metrics:
        raise HTTPException(status_code=404, detail="Métricas no encontradas para este video")
    return metrics

# GET /api/analytics/metrics/course/{course_id}
@router.get("/course/{course_id}")
def get_course_metrics(course_id: int, service: MetricsService = Depends(get_service)):
    """Retorna métricas agregadas de un curso (RF-035)"""
    return service.get_course_metrics(course_id)

# GET /api/analytics/metrics/teacher/{teacher_id}
@router.get("/teacher/{teacher_id}")
def get_teacher_stats(teacher_id: int, service: MetricsService = Depends(get_service)):
    """Retorna estadísticas de un docente (RF-035)"""
    return service.get_teacher_stats(teacher_id)

# GET /api/analytics/metrics/student/{student_id}/course/{course_id}
@router.get("/student/{student_id}/course/{course_id}")
def get_student_progress(
    student_id: int,
    course_id: int,
    service: MetricsService = Depends(get_service)
):
    """Retorna progreso de un estudiante en un curso (RF-032)"""
    return service.get_student_progress(student_id, course_id)

# POST /api/analytics/metrics/sync/video/{video_id}
@router.post("/sync/video/{video_id}")
def sync_video_metrics(video_id: int, service: MetricsService = Depends(get_service)):
    """
    Sincroniza métricas de un video desde el servicio de Reproducción via gRPC.
    Llama al SP sp_sync_video_metrics de analytics_mysql.sql
    """
    result = service.sync_video_from_grpc(video_id)
    if not result:
        raise HTTPException(status_code=503, detail="Error al sincronizar con servicio de Reproducción")
    return {"message": "Métricas sincronizadas exitosamente", "data": result}
