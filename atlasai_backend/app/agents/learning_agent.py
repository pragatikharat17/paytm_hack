"""
Agent 6: Learning Agent
-----------------------
Captures successful human-approved resolution playbooks.
When human supervisors approve edge cases, the Learning Agent updates resolution
playbook weights so future cases benefit from expert supervision feedback loops.
"""

import hashlib
import datetime
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.models.models import ResolutionPlaybook, ApprovalRequest, Payment, Complaint


class LearningAgent:
    NAME = "LearningAgent"

    @classmethod
    def learn_from_approval(
        cls,
        db: Session,
        approval: ApprovalRequest,
        payment: Payment,
        complaint: Complaint
    ) -> Dict[str, Any]:
        # Formulate pattern hash based on key conditions
        pattern_str = f"status={payment.status}:bank={payment.bank_status}:amt_bucket={int(payment.amount // 500) * 500}"
        pattern_hash = hashlib.sha256(pattern_str.encode()).hexdigest()[:16]

        existing = db.query(ResolutionPlaybook).filter_by(pattern_hash=pattern_hash).first()
        if existing:
            existing.success_count += 1
            action_taken = "INCREMENTED_PLAYBOOK"
            playbook_id = existing.id
        else:
            new_playbook = ResolutionPlaybook(
                pattern_hash=pattern_hash,
                scenario_name=f"Approved Resolution: {payment.status} / {payment.amount} INR",
                intent=complaint.intent or "FAILED_PAYMENT_REFUND",
                conditions={
                    "payment_status": payment.status,
                    "bank_status": payment.bank_status,
                    "amount": payment.amount,
                    "admin_notes": approval.admin_notes
                },
                recommended_action="APPROVE_AND_REFUND",
                success_count=1,
                created_at=datetime.datetime.utcnow()
            )
            db.add(new_playbook)
            db.commit()
            action_taken = "CREATED_PLAYBOOK"
            playbook_id = new_playbook.id

        return {
            "action": action_taken,
            "pattern_hash": pattern_hash,
            "playbook_id": playbook_id,
            "reasoning": f"Captured human supervisor decision into playbook {pattern_hash} for continuous autonomous alignment."
        }
