"""
Agent 5: Case Memory Agent
--------------------------
Maintains case history, checks for duplicate active/settled refund requests,
and retrieves contextually similar resolved cases.
"""

from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session
from app.models.models import Complaint, RefundRequest, ResolutionPlaybook


class CaseMemoryAgent:
    NAME = "CaseMemoryAgent"

    @classmethod
    def check_memory(
        cls,
        db: Session,
        payment_id: Optional[str],
        customer_id: Optional[str],
        intent: str
    ) -> Dict[str, Any]:
        tools_called = ["db.query(RefundRequest)"]

        # 1. Check for existing active or completed refunds for this payment
        existing_refund = None
        if payment_id:
            existing_refund = (
                db.query(RefundRequest)
                .filter_by(payment_id=payment_id)
                .order_by(RefundRequest.created_at.desc())
                .first()
            )

        tools_called.append("db.query(Complaint)")
        previous_complaints = []
        if customer_id:
            previous_complaints = (
                db.query(Complaint)
                .filter_by(customer_id=customer_id)
                .order_by(Complaint.created_at.desc())
                .limit(5)
                .all()
            )

        tools_called.append("db.query(ResolutionPlaybook)")
        similar_playbooks = (
            db.query(ResolutionPlaybook)
            .filter_by(intent=intent)
            .order_by(ResolutionPlaybook.success_count.desc())
            .limit(3)
            .all()
        )

        has_duplicate_risk = False
        duplicate_reason = None
        if existing_refund and existing_refund.status in ["COMPLETED", "PROCESSING", "APPROVED"]:
            has_duplicate_risk = True
            duplicate_reason = (
                f"Existing refund {existing_refund.refund_id} found in state {existing_refund.status}. "
                "Idempotency guard active."
            )

        evidence = {
            "existing_refund_found": bool(existing_refund),
            "existing_refund_id": existing_refund.refund_id if existing_refund else None,
            "existing_refund_status": existing_refund.status if existing_refund else None,
            "has_duplicate_risk": has_duplicate_risk,
            "duplicate_reason": duplicate_reason,
            "previous_complaints_count": len(previous_complaints),
            "matching_playbooks": [
                {
                    "scenario": p.scenario_name,
                    "action": p.recommended_action,
                    "success_count": p.success_count
                }
                for p in similar_playbooks
            ]
        }

        reasoning = (
            f"Case memory checked. Found {len(previous_complaints)} prior complaints for customer. "
            f"Duplicate refund risk: {'YES - BLOCKED' if has_duplicate_risk else 'None detected'}. "
            f"Retrieved {len(similar_playbooks)} matching resolution playbooks."
        )

        return {
            "existing_refund": existing_refund,
            "has_duplicate_risk": has_duplicate_risk,
            "reasoning": reasoning,
            "evidence": evidence,
            "tools_called": tools_called
        }
