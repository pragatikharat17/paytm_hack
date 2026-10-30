import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import RefundRequest, Payment, Complaint
from app.schemas.schemas import RefundCreate, RefundResponse
from app.policy_engine import PolicyEngine
from app.simulated_payment_api import simulated_gateway
from app.services.audit_service import AuditService

router = APIRouter(prefix="/api/refunds", tags=["Refunds"])


@router.post("/request", response_model=RefundResponse)
def request_refund(req: RefundCreate, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter_by(payment_id=req.payment_id.upper()).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found")

    idempotency_key = req.idempotency_key or f"IDEM_{payment.payment_id}_{uuid.uuid4().hex[:6]}"
    existing = db.query(RefundRequest).filter_by(idempotency_key=idempotency_key).first()
    if existing:
        return existing

    # Check duplicate completed refunds
    prior_completed = (
        db.query(RefundRequest)
        .filter_by(payment_id=payment.payment_id, status="COMPLETED")
        .first()
    )
    if prior_completed:
        raise HTTPException(status_code=409, detail=f"Refund already completed under ID {prior_completed.refund_id}")

    refund_id = f"REF_{uuid.uuid4().hex[:8].upper()}"
    status = "REQUESTED"
    
    # If amount exceeds limit, mark PENDING_APPROVAL
    if req.amount > PolicyEngine.AUTO_REFUND_THRESHOLD_INR:
        status = "PENDING_APPROVAL"
        refund = RefundRequest(
            refund_id=refund_id,
            payment_id=payment.payment_id,
            complaint_id=req.complaint_id,
            amount=req.amount,
            status=status,
            reason=req.reason,
            idempotency_key=idempotency_key
        )
        db.add(refund)
        db.commit()
        db.refresh(refund)
        return refund

    # Within threshold -> Initiate and Verify with simulated gateway
    init_res = simulated_gateway.initiate_refund(
        payment_id=payment.payment_id,
        amount=req.amount,
        idempotency_key=idempotency_key,
        reason=req.reason
    )
    verify_res = simulated_gateway.verify_refund_completion(init_res["gateway_refund_ref"])
    status = "COMPLETED" if verify_res.get("verified") else "FAILED"

    refund = RefundRequest(
        refund_id=refund_id,
        payment_id=payment.payment_id,
        complaint_id=req.complaint_id,
        amount=req.amount,
        status=status,
        reason=req.reason,
        idempotency_key=idempotency_key,
        gateway_refund_ref=init_res["gateway_refund_ref"]
    )
    db.add(refund)
    payment.status = "REVERSED" if status == "COMPLETED" else payment.status
    db.commit()
    db.refresh(refund)

    AuditService.log_event(
        db=db,
        case_id=payment.payment_id,
        event_type="DIRECT_REFUND_REQUESTED",
        actor="API_CLIENT",
        action="CREATE_REFUND",
        details={"refund_id": refund_id, "amount": req.amount, "status": status}
    )
    return refund


@router.get("", response_model=List[RefundResponse])
def list_refunds(payment_id: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(RefundRequest)
    if payment_id:
        query = query.filter_by(payment_id=payment_id.upper())
    return query.order_by(RefundRequest.created_at.desc()).all()


@router.get("/{id}", response_model=RefundResponse)
def get_refund(id: str, db: Session = Depends(get_db)):
    refund = None
    if id.isdigit():
        refund = db.query(RefundRequest).filter_by(id=int(id)).first()
    if not refund:
        refund = db.query(RefundRequest).filter_by(refund_id=id).first()

    if not refund:
        raise HTTPException(status_code=404, detail="Refund request not found")
    return refund
