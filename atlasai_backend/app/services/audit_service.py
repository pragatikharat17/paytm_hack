import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.models import AuditLog


class AuditService:
    @staticmethod
    def log_event(
        db: Session,
        case_id: str,
        event_type: str,
        actor: str,
        action: str,
        details: Optional[Dict[str, Any]] = None
    ) -> AuditLog:
        """
        Record an immutable audit log entry in the SQLite database.
        """
        entry = AuditLog(
            case_id=case_id,
            event_type=event_type,
            actor=actor,
            action=action,
            details=details or {},
            timestamp=datetime.datetime.utcnow()
        )
        db.add(entry)
        db.commit()
        db.refresh(entry)
        return entry
