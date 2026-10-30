import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import Complaint
from app.schemas.schemas import ComplaintCreate, ComplaintResponse
from app.services.audit_service import AuditService

router = APIRouter(prefix="/api/complaints", tags=["Complaints"])


@router.post("", response_model=ComplaintResponse)
def create_complaint(req: ComplaintCreate, db: Session = Depends(get_db)):
    complaint_id = f"CMP_{uuid.uuid4().hex[:8].upper()}"
    complaint = Complaint(
        complaint_id=complaint_id,
        customer_id=req.customer_id,
        payment_id=req.payment_id,
        raw_text=req.raw_text,
        original_language=req.language or "en",
        status="NEW"
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)

    AuditService.log_event(
        db=db,
        case_id=complaint_id,
        event_type="COMPLAINT_FILED",
        actor="CUSTOMER",
        action="CREATE_COMPLAINT_MANUAL",
        details={"raw_text": req.raw_text, "payment_id": req.payment_id}
    )
    return complaint


@router.get("", response_model=List[ComplaintResponse])
def list_complaints(
    customer_id: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    query = db.query(Complaint)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    if status:
        query = query.filter_by(status=status)
    return query.order_by(Complaint.created_at.desc()).limit(limit).all()


@router.get("/{id}", response_model=ComplaintResponse)
def get_complaint(id: str, db: Session = Depends(get_db)):
    # Support both complaint_id (e.g. CMP_xxx) or numeric primary key
    complaint = None
    if id.isdigit():
        complaint = db.query(Complaint).filter_by(id=int(id)).first()
    if not complaint:
        complaint = db.query(Complaint).filter_by(complaint_id=id).first()

    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return complaint
