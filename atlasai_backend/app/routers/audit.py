from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import AuditLog
from app.schemas.schemas import AuditLogResponse

router = APIRouter(prefix="/api/audit", tags=["Audit Trail"])


@router.get("/{case_id}", response_model=List[AuditLogResponse])
def get_audit_trail(case_id: str, db: Session = Depends(get_db)):
    """
    Retrieve complete immutable audit history for a complaint or transaction.
    """
    logs = (
        db.query(AuditLog)
        .filter_by(case_id=case_id)
        .order_by(AuditLog.timestamp.desc())
        .all()
    )
    return logs
