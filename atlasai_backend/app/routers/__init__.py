from app.routers.complaints import router as complaints_router
from app.routers.payments import router as payments_router
from app.routers.agents import router as agents_router
from app.routers.refunds import router as refunds_router
from app.routers.admin import router as admin_router
from app.routers.audit import router as audit_router
from app.routers.voice import router as voice_router

__all__ = [
    "complaints_router",
    "payments_router",
    "agents_router",
    "refunds_router",
    "admin_router",
    "audit_router",
    "voice_router",
]
