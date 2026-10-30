import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models.models import (
    Complaint,
    Payment,
    Order,
    Customer,
    RefundRequest,
    ApprovalRequest,
    SupportTicket,
    AuditLog,
    AgentDecision
)
from app.schemas.schemas import (
    ApprovalResponse,
    ApprovalActionRequest,
    AdminCaseDetail,
    AdminKPIResponse,
    ComplaintResponse
)
from app.simulated_payment_api import simulated_gateway
from app.services.audit_service import AuditService
from app.agents.learning_agent import LearningAgent
from app.seed_data import seed_database

router = APIRouter(prefix="/api/admin", tags=["Admin Support Operations"])


def verify_admin_auth(x_admin_token: Optional[str] = Header(None)):
    """
    Demo authentication guard for hackathon operations.
    Accepts standard demo token or defaults to allow dashboard access.
    """
    if x_admin_token and x_admin_token not in ["atlasai_admin_secret_2026", "demo_admin"]:
        raise HTTPException(status_code=401, detail="Invalid admin authorization token")
    return True


@router.get("/kpis", response_model=AdminKPIResponse)
def get_dashboard_kpis(db: Session = Depends(get_db)):
    total_complaints = db.query(Complaint).count()
    resolved_cases = db.query(Complaint).filter(Complaint.status.in_(["AUTO_RESOLVED", "APPROVED"])).count()
    pending_approvals = db.query(ApprovalRequest).filter_by(status="PENDING").count()
    escalated_cases = db.query(Complaint).filter_by(status="ESCALATED").count()
    
    total_refund = (
        db.query(func.sum(RefundRequest.amount))
        .filter(RefundRequest.status == "COMPLETED")
        .scalar()
    ) or 0.0

    return AdminKPIResponse(
        total_complaints=total_complaints,
        resolved_cases=resolved_cases,
        pending_approvals=pending_approvals,
        escalated_cases=escalated_cases,
        total_refund_amount=float(total_refund)
    )


@router.get("/cases")
def list_admin_cases(
    status: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    query = db.query(Complaint)
    if status:
        query = query.filter_by(status=status)
    complaints = query.order_by(Complaint.created_at.desc()).limit(limit).all()

    results = []
    for c in complaints:
        payment = db.query(Payment).filter_by(payment_id=c.payment_id).first() if c.payment_id else None
        refund = db.query(RefundRequest).filter_by(complaint_id=c.complaint_id).first()
        approval = db.query(ApprovalRequest).filter_by(complaint_id=c.complaint_id).first()
        ticket = db.query(SupportTicket).filter_by(complaint_id=c.complaint_id).first()

        results.append({
            "complaint_id": c.complaint_id,
            "customer_id": c.customer_id,
            "payment_id": c.payment_id,
            "amount": payment.amount if payment else None,
            "raw_text": c.raw_text,
            "language": c.original_language,
            "intent": c.intent,
            "status": c.status,
            "resolution_summary": c.resolution_summary,
            "created_at": c.created_at,
            "has_refund": bool(refund),
            "refund_status": refund.status if refund else None,
            "approval_status": approval.status if approval else None,
            "ticket_status": ticket.status if ticket else None
        })
    return results


@router.get("/cases/{complaint_id}", response_model=AdminCaseDetail)
def get_admin_case_detail(complaint_id: str, db: Session = Depends(get_db)):
    complaint = db.query(Complaint).filter_by(complaint_id=complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Case not found")

    customer = db.query(Customer).filter_by(customer_id=complaint.customer_id).first() if complaint.customer_id else None
    payment = db.query(Payment).filter_by(payment_id=complaint.payment_id).first() if complaint.payment_id else None
    order = db.query(Order).filter_by(order_id=payment.order_id).first() if (payment and payment.order_id) else None
    refund = db.query(RefundRequest).filter_by(complaint_id=complaint.complaint_id).first()
    approval = db.query(ApprovalRequest).filter_by(complaint_id=complaint.complaint_id).first()
    ticket = db.query(SupportTicket).filter_by(complaint_id=complaint.complaint_id).first()
    audit_logs = db.query(AuditLog).filter_by(case_id=complaint.complaint_id).order_by(AuditLog.timestamp.desc()).all()
    decisions = db.query(AgentDecision).filter_by(complaint_id=complaint.complaint_id).all()

    return AdminCaseDetail(
        complaint=complaint,
        customer=customer,
        payment=payment,
        order=order,
        refund=refund,
        approval=approval,
        ticket=ticket,
        audit_logs=audit_logs,
        agent_decisions=decisions
    )


@router.get("/approvals", response_model=List[ApprovalResponse])
def list_approvals(status: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(ApprovalRequest)
    if status:
        query = query.filter_by(status=status)
    return query.order_by(ApprovalRequest.created_at.desc()).all()


@router.post("/approvals/{id}/approve", response_model=ApprovalResponse)
def approve_request(
    id: str,
    req: ApprovalActionRequest,
    db: Session = Depends(get_db)
):
    approval = None
    if id.isdigit():
        approval = db.query(ApprovalRequest).filter_by(id=int(id)).first()
    if not approval:
        approval = db.query(ApprovalRequest).filter_by(approval_id=id).first()

    if not approval:
        raise HTTPException(status_code=404, detail="Approval request not found")

    if approval.status != "PENDING":
        raise HTTPException(status_code=400, detail=f"Request is already {approval.status}")

    complaint = db.query(Complaint).filter_by(complaint_id=approval.complaint_id).first()
    payment = db.query(Payment).filter_by(payment_id=complaint.payment_id).first() if complaint else None
    refund = db.query(RefundRequest).filter_by(refund_id=approval.refund_id).first() if approval.refund_id else None

    # Transition Approval -> APPROVED
    approval.status = "APPROVED"
    approval.admin_notes = req.notes or "Approved by Support Lead"
    approval.decided_by = req.admin_name
    approval.decided_at = datetime.datetime.utcnow()

    # Now execute simulated refund and VERIFY
    if refund and payment:
        refund.status = "APPROVED"
        refund.approved_by = req.admin_name
        db.commit()

        # Call simulated gateway
        init_res = simulated_gateway.initiate_refund(
            payment_id=payment.payment_id,
            amount=approval.amount,
            idempotency_key=refund.idempotency_key,
            reason=f"Human approved: {approval.admin_notes}"
        )
        refund.status = "PROCESSING"
        refund.gateway_refund_ref = init_res["gateway_refund_ref"]
        db.commit()

        # Crucial verification before declaring completed
        verify_res = simulated_gateway.verify_refund_completion(init_res["gateway_refund_ref"])
        if verify_res.get("verified"):
            refund.status = "COMPLETED"
            payment.status = "REVERSED"
            if complaint:
                complaint.status = "APPROVED"
                complaint.resolution_summary = (
                    f"Your refund of ₹{approval.amount:.2f} was approved by Support Lead ({req.admin_name}) "
                    f"and successfully credited to your bank account. Refund Ref: {refund.refund_id} "
                    f"(UTR: {verify_res.get('utr_number')})."
                )

    AuditService.log_event(
        db=db,
        case_id=approval.complaint_id,
        event_type="APPROVAL_GRANTED",
        actor=f"ADMIN:{req.admin_name}",
        action="APPROVE_AND_EXECUTE_REFUND",
        details={
            "approval_id": approval.approval_id,
            "refund_id": approval.refund_id,
            "amount": approval.amount,
            "notes": req.notes
        }
    )

    # Invoke Learning Agent to reinforce human-aligned policy playbook
    if payment and complaint:
        LearningAgent.learn_from_approval(
            db=db,
            approval=approval,
            payment=payment,
            complaint=complaint
        )

    db.commit()
    db.refresh(approval)
    return approval


@router.post("/approvals/{id}/reject", response_model=ApprovalResponse)
def reject_request(
    id: str,
    req: ApprovalActionRequest,
    db: Session = Depends(get_db)
):
    approval = None
    if id.isdigit():
        approval = db.query(ApprovalRequest).filter_by(id=int(id)).first()
    if not approval:
        approval = db.query(ApprovalRequest).filter_by(approval_id=id).first()

    if not approval:
        raise HTTPException(status_code=404, detail="Approval request not found")

    approval.status = "REJECTED"
    approval.admin_notes = req.notes or "Rejected by Support Lead"
    approval.decided_by = req.admin_name
    approval.decided_at = datetime.datetime.utcnow()

    complaint = db.query(Complaint).filter_by(complaint_id=approval.complaint_id).first()
    if complaint:
        complaint.status = "REJECTED"
        complaint.resolution_summary = f"Refund request was reviewed and rejected. Reason: {approval.admin_notes}"

    refund = db.query(RefundRequest).filter_by(refund_id=approval.refund_id).first() if approval.refund_id else None
    if refund:
        refund.status = "REJECTED"
        refund.failure_reason = approval.admin_notes

    AuditService.log_event(
        db=db,
        case_id=approval.complaint_id,
        event_type="APPROVAL_REJECTED",
        actor=f"ADMIN:{req.admin_name}",
        action="REJECT_REFUND_REQUEST",
        details={
            "approval_id": approval.approval_id,
            "refund_id": approval.refund_id,
            "notes": req.notes
        }
    )

    db.commit()
    db.refresh(approval)
    return approval


@router.post("/seed")
def reseed_demo_data(db: Session = Depends(get_db)):
    """
    Reseed demo data (customers, orders, payments, playbooks).
    """
    seed_database(db)
    return {"message": "Demo data seeded successfully"}
