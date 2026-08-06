# app/reports/router.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.reports.service import ReportsService

router = APIRouter()

def get_service(db: Session = Depends(get_db)) -> ReportsService:
    return ReportsService(db)

# GET /api/analytics/reports/top-videos
@router.get("/top-videos")
def get_top_videos(limit: int = 10, service: ReportsService = Depends(get_service)):
    """Top videos por porcentaje de recomendación usando vw_top_videos (RF-017)"""
    return service.get_top_videos(limit)

# GET /api/analytics/reports/system-stats
@router.get("/system-stats")
def get_system_stats(service: ReportsService = Depends(get_service)):
    """Estadísticas globales del sistema usando vw_system_stats (RF-033)"""
    return service.get_system_stats()

# GET /api/analytics/reports/teacher/{teacher_id}/performance
@router.get("/teacher/{teacher_id}/performance")
def get_teacher_performance(
    teacher_id: int,
    service: ReportsService = Depends(get_service)
):
    """Rendimiento de un docente usando vw_teacher_performance (RF-035)"""
    return service.get_teacher_performance(teacher_id)

# GET /api/analytics/reports/course/{course_id}/progress
@router.get("/course/{course_id}/progress")
def get_course_progress(
    course_id: int,
    service: ReportsService = Depends(get_service)
):
    """Progreso de estudiantes en un curso usando vw_course_student_progress"""
    return service.get_course_progress(course_id)

# GET /api/analytics/reports/engagement/{video_id}
@router.get("/engagement/{video_id}")
def get_video_engagement(
    video_id: int,
    service: ReportsService = Depends(get_service)
):
    """Nivel de engagement de un video usando fn_engagement_level (MySQL función)"""
    return service.get_video_engagement(video_id)
