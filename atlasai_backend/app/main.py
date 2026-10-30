from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base, SessionLocal
from app.seed_data import seed_database
from app.services.sarvam_service import sarvam_service
from app.routers import (
    complaints_router,
    payments_router,
    agents_router,
    refunds_router,
    admin_router,
    audit_router,
    voice_router,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite database schema
    Base.metadata.create_all(bind=engine)
    # Seed fictional demo transactions (PAY1001, PAY1002, PAY1003, PAY1004)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title="AtlasAI — Autonomous AI Customer Resolution Teammate",
    description=(
        "Autonomous Customer Resolution Agent system for Paytm Build for India AI Hackathon 2026. "
        "Demonstrates real multi-agent decision-making, tool execution, deterministic policy guardrails, "
        "and Sarvam AI multilingual voice understanding."
    ),
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter mobile/web clients and React Admin Dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all required API routers
app.include_router(complaints_router)
app.include_router(payments_router)
app.include_router(agents_router)
app.include_router(refunds_router)
app.include_router(admin_router)
app.include_router(audit_router)
app.include_router(voice_router)


@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "ok",
        "service": "AtlasAI Autonomous Customer Resolution Backend",
        "version": "1.0.0",
        "hackathon": "Paytm Build for India AI Hackathon 2026",
        "track": "Track 3: Autonomous AI Teammates",
        "sarvam_ai_configured": sarvam_service.is_configured
    }


@app.get("/ping", tags=["System"])
def ping():
    return {"status": "pong", "message": "AtlasAI backend online"}