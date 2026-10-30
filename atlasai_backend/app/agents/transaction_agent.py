"""
Agent 2: Transaction Agent
--------------------------
Retrieves payment and order records from backend database and simulated payment gateway.
Detects transaction mismatches and provides empirical transaction evidence.
"""

from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.models import Payment, Order
from app.simulated_payment_api import simulated_gateway


class TransactionAgent:
    NAME = "TransactionAgent"

    @classmethod
    def investigate(
        cls,
        db: Session,
        payment_id: Optional[str],
        customer_id: Optional[str] = None
    ) -> Dict[str, Any]:
        tools_called = ["db.query(Payment)"]
        
        # If payment_id not provided, look for latest payment by customer
        payment = None
        if payment_id:
            payment = db.query(Payment).filter_by(payment_id=payment_id).first()
        elif customer_id:
            payment = db.query(Payment).filter_by(customer_id=customer_id).order_by(Payment.created_at.desc()).first()

        if not payment:
            return {
                "success": False,
                "payment": None,
                "order": None,
                "status": "NOT_FOUND",
                "reasoning": f"Transaction record '{payment_id or 'latest'}' not found in payment system.",
                "evidence": {},
                "tools_called": tools_called
            }

        tools_called.append("db.query(Order)")
        order = db.query(Order).filter_by(order_id=payment.order_id).first()

        tools_called.append("simulated_gateway.fetch_transaction")
        gateway_info = simulated_gateway.fetch_transaction(payment.payment_id)

        # Detect mismatches
        mismatch_detected = False
        mismatch_reason = None
        if payment.status == "FAILED" and payment.bank_status == "DEBITED":
            mismatch_detected = True
            mismatch_reason = "Transaction state mismatch: Merchant payment FAILED but customer bank account was DEBITED."
        elif payment.status == "PENDING":
            mismatch_detected = True
            mismatch_reason = "Transaction pending settlement between bank switch and merchant."

        evidence = {
            "payment_id": payment.payment_id,
            "order_id": payment.order_id,
            "amount": payment.amount,
            "currency": payment.currency,
            "method": payment.method,
            "payment_status": payment.status,
            "gateway_status": payment.gateway_status,
            "bank_status": payment.bank_status,
            "bank_ref": payment.bank_ref,
            "error_code": payment.error_code,
            "failure_reason": payment.failure_reason,
            "merchant_name": order.merchant_name if order else "Unknown Merchant",
            "order_status": order.status if order else "UNKNOWN",
            "mismatch_detected": mismatch_detected,
            "mismatch_reason": mismatch_reason,
            "gateway_switch_data": gateway_info
        }

        reasoning = (
            f"Retrieved payment {payment.payment_id} for ₹{payment.amount}. "
            f"Payment status is {payment.status}, gateway status is {payment.gateway_status}, "
            f"and bank status is {payment.bank_status}. "
        )
        if mismatch_detected:
            reasoning += f"Notice: {mismatch_reason}"

        return {
            "success": True,
            "payment": payment,
            "order": order,
            "status": payment.status,
            "reasoning": reasoning,
            "evidence": evidence,
            "tools_called": tools_called
        }
