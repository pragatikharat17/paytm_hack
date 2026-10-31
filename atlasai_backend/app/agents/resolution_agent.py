"""
Agent 4: Resolution Agent
-------------------------
Executes the approved resolution path:
- Initiates simulated refund with idempotency
- Submits approval request for sensitive high-ticket cases
- Creates support ticket for disputes and investigations
- CRITICAL RULE: Verifies bank switch confirmation before claiming refund completion!
"""

import uuid
import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.models.models import (
    Complaint,
    Payment,
    Order,
    RefundRequest,
    ApprovalRequest,
    SupportTicket
)
from app.simulated_payment_api import simulated_gateway
from app.services.audit_service import AuditService


class ResolutionAgent:
    NAME = "ResolutionAgent"

    @classmethod
    def execute_resolution(
        cls,
        db: Session,
        complaint: Complaint,
        payment: Optional[Payment],
        order: Optional[Order],
        policy_decision: Dict[str, Any]
    ) -> Dict[str, Any]:
        action = policy_decision["action"]
        tools_called = []
        evidence = {}
        outcome = "UNKNOWN"
        final_message = ""
        refund_record = None
        approval_record = None
        ticket_record = None

        # -------------------------------------------------------------
        # Path 1: AUTO_REFUND (Scenario A: e.g. PAY1001 ₹499 <= ₹1000)
        # -------------------------------------------------------------
        if action == "AUTO_REFUND" and payment:
            tools_called.append("simulated_gateway.initiate_refund")
            idempotency_key = f"IDEM_{complaint.complaint_id}_{payment.payment_id}"
            
            # 1. Create Refund Request in REQUESTED state
            refund_id = f"REF_{uuid.uuid4().hex[:8].upper()}"
            refund = RefundRequest(
                refund_id=refund_id,
                payment_id=payment.payment_id,
                complaint_id=complaint.complaint_id,
                amount=payment.amount,
                status="REQUESTED",
                reason=f"Auto-resolved failed payment: {payment.failure_reason or 'Gateway timeout'}",
                idempotency_key=idempotency_key
            )
            db.add(refund)
            db.commit()

            # 2. Call Simulated Payment Gateway -> State PROCESSING
            tools_called.append("simulated_gateway.initiate_refund")
            init_res = simulated_gateway.initiate_refund(
                payment_id=payment.payment_id,
                amount=payment.amount,
                idempotency_key=idempotency_key,
                reason="Customer complaint failed payment auto-resolution"
            )
            refund.status = "PROCESSING"
            refund.gateway_refund_ref = init_res["gateway_refund_ref"]
            db.commit()

            # 3. VERIFY with banking switch before claiming completion
            tools_called.append("simulated_gateway.verify_refund_completion")
            verify_res = simulated_gateway.verify_refund_completion(init_res["gateway_refund_ref"])
            
            if verify_res.get("verified"):
                refund.status = "COMPLETED"
                payment.status = "REVERSED"
                complaint.status = "AUTO_RESOLVED"
                outcome = "AUTO_RESOLVED"
                
                AuditService.log_event(
                    db=db,
                    case_id=complaint.complaint_id,
                    event_type="REFUND_COMPLETED",
                    actor=cls.NAME,
                    action="EXECUTE_AUTO_REFUND_VERIFIED",
                    details={
                        "refund_id": refund.refund_id,
                        "amount": payment.amount,
                        "utr": verify_res.get("utr_number"),
                        "gateway_ref": init_res["gateway_refund_ref"]
                    }
                )

                final_message = (
                    f"Good news! Your payment of ₹{payment.amount:.2f} failed due to a bank timeout, "
                    f"and an instant refund has been successfully credited back to your original payment source. "
                    f"Refund Reference: {refund.refund_id} (Bank UTR: {verify_res.get('utr_number')})."
                )
            else:
                refund.status = "FAILED"
                refund.failure_reason = "Bank switch settlement verification timed out."
                complaint.status = "ESCALATED"
                outcome = "ESCALATED"
                final_message = (
                    f"Refund of ₹{payment.amount:.2f} was initiated, but settlement confirmation is pending. "
                    f"Our finance team has been alerted under Reference: {refund.refund_id}."
                )

            db.commit()
            refund_record = refund
            evidence["refund"] = {
                "refund_id": refund.refund_id,
                "amount": refund.amount,
                "status": refund.status,
                "utr": verify_res.get("utr_number"),
                "gateway_ref": refund.gateway_refund_ref
            }

        # -------------------------------------------------------------
        # Path 2: REQUIRE_APPROVAL (Scenario B: e.g. PAY1002 ₹1,299 > ₹1000)
        # -------------------------------------------------------------
        elif action == "REQUIRE_APPROVAL" and payment:
            tools_called.append("db.add(ApprovalRequest)")
            approval_id = f"APR_{uuid.uuid4().hex[:8].upper()}"
            refund_id = f"REF_{uuid.uuid4().hex[:8].upper()}"

            # Create preliminary refund in PENDING_APPROVAL
            refund = RefundRequest(
                refund_id=refund_id,
                payment_id=payment.payment_id,
                complaint_id=complaint.complaint_id,
                amount=payment.amount,
                status="PENDING_APPROVAL",
                reason=policy_decision["reason"],
                idempotency_key=f"IDEM_APR_{complaint.complaint_id}_{payment.payment_id}"
            )
            db.add(refund)
            db.commit()

            approval = ApprovalRequest(
                approval_id=approval_id,
                complaint_id=complaint.complaint_id,
                refund_id=refund_id,
                amount=payment.amount,
                reason=policy_decision["reason"],
                risk_score=policy_decision["risk_score"],
                required_role="SUPPORT_LEAD",
                status="PENDING"
            )
            db.add(approval)
            complaint.status = "PENDING_APPROVAL"
            outcome = "PENDING_APPROVAL"
            db.commit()

            AuditService.log_event(
                db=db,
                case_id=complaint.complaint_id,
                event_type="APPROVAL_REQUESTED",
                actor=cls.NAME,
                action="SUBMIT_FOR_ADMIN_SIGN_OFF",
                details={
                    "approval_id": approval_id,
                    "refund_id": refund_id,
                    "amount": payment.amount,
                    "reason": policy_decision["reason"]
                }
            )

            final_message = (
                f"We investigated your transaction {payment.payment_id} for ₹{payment.amount:.2f}. "
                f"Because this amount exceeds autonomous threshold limits (₹1,000.00), your refund request "
                f"has been queued for priority approval with our Support Lead (Approval ID: {approval_id}). "
                f"You will receive an update as soon as the supervisor reviews it."
            )
            approval_record = approval
            refund_record = refund
            evidence["approval"] = {
                "approval_id": approval.approval_id,
                "amount": approval.amount,
                "required_role": approval.required_role,
                "status": approval.status
            }

        # -------------------------------------------------------------
        # Path 3: ESCALATE (Scenario C: e.g. PAY1003 dispute / PAY1004 pending)
        # -------------------------------------------------------------
        elif action == "ESCALATE":
            tools_called.append("db.add(SupportTicket)")
            ticket_id = f"TKT_{uuid.uuid4().hex[:8].upper()}"
            fraud_trigger = policy_decision.get("evidence", {}).get("rules_evaluated", {}).get("fraud_trigger", False)
            category = "FRAUD_DISPUTE" if fraud_trigger else "PAYMENT_INVESTIGATION"
            priority = "HIGH" if category == "FRAUD_DISPUTE" else "MEDIUM"

            ticket = SupportTicket(
                ticket_id=ticket_id,
                complaint_id=complaint.complaint_id,
                customer_id=complaint.customer_id,
                payment_id=payment.payment_id if payment else None,
                priority=priority,
                category=category,
                subject=f"Autonomous Escalation: {category.replace('_', ' ').title()}",
                description=policy_decision["reason"],
                status="OPEN",
                assigned_to="Priority Escalation Desk"
            )
            db.add(ticket)
            complaint.status = "ESCALATED"
            outcome = "ESCALATED"
            db.commit()

            AuditService.log_event(
                db=db,
                case_id=complaint.complaint_id,
                event_type="TICKET_ESCALATED",
                actor=cls.NAME,
                action="CREATE_SUPPORT_TICKET",
                details={
                    "ticket_id": ticket_id,
                    "priority": priority,
                    "category": category,
                    "reason": policy_decision["reason"]
                }
            )

            final_message = (
                f"Your issue has been evaluated by our Risk & Policy Teammate. "
                f"{policy_decision['reason']} "
                f"A priority support ticket ({ticket_id}) has been created and assigned to our specialized team."
            )
            ticket_record = ticket
            evidence["ticket"] = {
                "ticket_id": ticket.ticket_id,
                "priority": ticket.priority,
                "category": ticket.category,
                "status": ticket.status
            }

        # -------------------------------------------------------------
        # Path 4: REJECT (Duplicate refund or invalid)
        # -------------------------------------------------------------
        else:
            complaint.status = "REJECTED"
            outcome = "REJECTED"
            final_message = policy_decision["reason"]
            AuditService.log_event(
                db=db,
                case_id=complaint.complaint_id,
                event_type="COMPLAINT_REJECTED",
                actor=cls.NAME,
                action="REJECT_ACTION",
                details={"reason": policy_decision["reason"]}
            )
            db.commit()

        complaint.resolution_summary = final_message
        db.commit()

        reasoning = (
            f"Executed resolution action '{action}'. Outcome set to '{outcome}'. "
            f"Evidence verified against payment switch."
        )

        return {
            "outcome": outcome,
            "final_message": final_message,
            "reasoning": reasoning,
            "evidence": evidence,
            "tools_called": tools_called,
            "refund": refund_record,
            "approval": approval_record,
            "ticket": ticket_record
        }
