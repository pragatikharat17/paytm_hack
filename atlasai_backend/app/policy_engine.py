"""
AtlasAI Deterministic Policy and Risk Evaluation Engine
-------------------------------------------------------
SIMULATED POLICY NOTICE:
All thresholds and rules in this module are simulated for hackathon demonstration
purposes and do not represent official Paytm commercial, banking, or operational policies.
"""

from typing import Dict, Any, Optional
from app.models.models import Payment, Order, RefundRequest


class PolicyEvaluationResult:
    def __init__(
        self,
        eligible: bool,
        action: str,  # "AUTO_REFUND", "REQUIRE_APPROVAL", "ESCALATE", "REJECT", "INFO_ONLY"
        reason: str,
        risk_score: float,
        rules_evaluated: Dict[str, Any],
        requires_human_approval: bool = False
    ):
        self.eligible = eligible
        self.action = action
        self.reason = reason
        self.risk_score = risk_score
        self.rules_evaluated = rules_evaluated
        self.requires_human_approval = requires_human_approval

    def to_dict(self) -> Dict[str, Any]:
        return {
            "eligible": self.eligible,
            "action": self.action,
            "reason": self.reason,
            "risk_score": self.risk_score,
            "requires_human_approval": self.requires_human_approval,
            "rules_evaluated": self.rules_evaluated,
            "policy_disclaimer": "Simulated rule engine for hackathon demo only."
        }


class PolicyEngine:
    # Configurable demo refund thresholds
    AUTO_REFUND_THRESHOLD_INR: float = 1000.0  # Max limit for fully autonomous refund
    MAX_APPROVAL_LIMIT_INR: float = 10000.0   # Max limit for admin approval
    FRAUD_RISK_THRESHOLD: float = 0.60

    SUSPICIOUS_KEYWORDS = [
        "scam", "fraud", "hacked", "stolen", "unauthorized",
        "fake", "cheat", "cybercrime", "fir", "police", "not recognize"
    ]

    @classmethod
    def evaluate(
        cls,
        payment: Optional[Payment],
        order: Optional[Order],
        existing_refund: Optional[RefundRequest],
        intent: str,
        complaint_text: str
    ) -> PolicyEvaluationResult:
        rules_log = {}
        complaint_lower = complaint_text.lower()

        # 1. Check if payment exists
        if not payment:
            return PolicyEvaluationResult(
                eligible=False,
                action="ESCALATE",
                reason="Transaction record not found in payment system. Case escalated for manual lookup.",
                risk_score=0.7,
                rules_evaluated={"transaction_found": False},
                requires_human_approval=False
            )
        rules_log["transaction_found"] = True
        rules_log["payment_id"] = payment.payment_id
        rules_log["amount"] = payment.amount
        rules_log["payment_status"] = payment.status
        rules_log["gateway_status"] = payment.gateway_status
        rules_log["bank_status"] = payment.bank_status

        # 2. Check for duplicate or completed refund (Idempotency / Guardrail)
        if existing_refund and existing_refund.status in ["COMPLETED", "PROCESSING", "APPROVED"]:
            rules_log["duplicate_refund_prevented"] = True
            return PolicyEvaluationResult(
                eligible=False,
                action="REJECT",
                reason=f"A refund request ({existing_refund.refund_id}) already exists in status '{existing_refund.status}'. Duplicate refund blocked.",
                risk_score=0.1,
                rules_evaluated=rules_log,
                requires_human_approval=False
            )
        rules_log["duplicate_refund_prevented"] = False

        # 3. Fraud / Suspicious keywords analysis
        suspicious_matches = [w for w in cls.SUSPICIOUS_KEYWORDS if w in complaint_lower]
        risk_score = 0.05
        if suspicious_matches:
            risk_score += 0.65
            rules_log["suspicious_flags"] = suspicious_matches
        rules_log["calculated_risk_score"] = risk_score

        # 4. Check for dispute / fraud / unauthorized transaction
        if "dispute" in intent.lower() or "fraud" in intent.lower() or risk_score >= cls.FRAUD_RISK_THRESHOLD:
            # If payment was SUCCESS, and user disputes it -> Escalate to human fraud desk
            rules_log["fraud_trigger"] = True
            return PolicyEvaluationResult(
                eligible=False,
                action="ESCALATE",
                reason="Disputed or unrecognized transaction detected. Risk score exceeds automated threshold. Escalated to Tier-2 Fraud & Support desk.",
                risk_score=risk_score,
                rules_evaluated=rules_log,
                requires_human_approval=False
            )

        # 5. Check payment status: PENDING
        if payment.status == "PENDING" or payment.gateway_status == "PENDING":
            rules_log["pending_investigation"] = True
            return PolicyEvaluationResult(
                eligible=False,
                action="ESCALATE",
                reason="Payment is currently in PENDING state at banking switch. Bank settlement window (T+24h) is active. Automated dispute ticket created.",
                risk_score=0.3,
                rules_evaluated=rules_log,
                requires_human_approval=False
            )

        # 6. Check payment status: SUCCESS
        if payment.status == "SUCCESS":
            # Payment was successful and order delivered or valid
            order_status = order.status if order else "UNKNOWN"
            rules_log["order_status"] = order_status
            return PolicyEvaluationResult(
                eligible=False,
                action="ESCALATE",
                reason=f"Payment succeeded and order is '{order_status}'. Instant refund policy cannot auto-debit merchant. Escalated to Customer Operations.",
                risk_score=0.4,
                rules_evaluated=rules_log,
                requires_human_approval=False
            )

        # 7. Check payment status: FAILED with bank DEBITED (The classic failed payment scenario)
        if payment.status == "FAILED" and payment.bank_status == "DEBITED":
            rules_log["failed_with_debit"] = True

            # Evaluate amount against policy threshold
            if payment.amount <= cls.AUTO_REFUND_THRESHOLD_INR:
                # Within autonomous threshold (e.g. ₹499 <= ₹1,000)
                rules_log["within_auto_limit"] = True
                return PolicyEvaluationResult(
                    eligible=True,
                    action="AUTO_REFUND",
                    reason=f"Payment FAILED while bank was DEBITED. Amount ₹{payment.amount:.2f} is within simulated autonomous limit (₹{cls.AUTO_REFUND_THRESHOLD_INR:.2f}). Safe for auto-resolution.",
                    risk_score=0.05,
                    rules_evaluated=rules_log,
                    requires_human_approval=False
                )
            else:
                # Exceeds autonomous threshold (e.g. ₹1,299 > ₹1,000)
                rules_log["within_auto_limit"] = False
                rules_log["requires_admin_signoff"] = True
                return PolicyEvaluationResult(
                    eligible=True,
                    action="REQUIRE_APPROVAL",
                    reason=f"Payment FAILED while bank was DEBITED. Amount ₹{payment.amount:.2f} exceeds autonomous limit of ₹{cls.AUTO_REFUND_THRESHOLD_INR:.2f}. Requires Support Lead approval.",
                    risk_score=0.35,
                    rules_evaluated=rules_log,
                    requires_human_approval=True
                )

        # Default fallback escalation
        return PolicyEvaluationResult(
            eligible=False,
            action="ESCALATE",
            reason=f"Payment state ({payment.status}) requires specialized manual handling.",
            risk_score=0.5,
            rules_evaluated=rules_log,
            requires_human_approval=False
        )
