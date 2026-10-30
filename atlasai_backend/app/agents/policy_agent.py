"""
Agent 3: Policy and Risk Agent
------------------------------
Enforces deterministic policy rules and risk thresholds.
Validates refund limits, checks fraud indicators, determines human approval need,
and blocks unauthorized actions.
"""

from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.models import Payment, Order, RefundRequest
from app.policy_engine import PolicyEngine, PolicyEvaluationResult


class PolicyRiskAgent:
    NAME = "PolicyRiskAgent"

    @classmethod
    def evaluate_policy(
        cls,
        payment: Optional[Payment],
        order: Optional[Order],
        existing_refund: Optional[RefundRequest],
        intent: str,
        complaint_text: str
    ) -> Dict[str, Any]:
        tools_called = [
            "PolicyEngine.evaluate",
            "PolicyEngine.check_limits",
            "PolicyEngine.calculate_risk_score"
        ]

        result: PolicyEvaluationResult = PolicyEngine.evaluate(
            payment=payment,
            order=order,
            existing_refund=existing_refund,
            intent=intent,
            complaint_text=complaint_text
        )

        evidence = result.to_dict()

        return {
            "eligible": result.eligible,
            "action": result.action,
            "reason": result.reason,
            "risk_score": result.risk_score,
            "requires_human_approval": result.requires_human_approval,
            "reasoning": f"Policy evaluated: action='{result.action}'. {result.reason}",
            "evidence": evidence,
            "tools_called": tools_called
        }
