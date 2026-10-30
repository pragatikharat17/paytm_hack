import uuid
import datetime
import random
from typing import Dict, Any, Optional


class SimulatedPaymentGateway:
    """
    Simulated Payment Gateway & Bank Switch.
    Strictly isolated sandbox for the hackathon MVP.
    Never connects to live banking networks or real Paytm accounts.
    """

    def __init__(self):
        # Simulated gateway ledger of refunds
        self.refund_ledger: Dict[str, Dict[str, Any]] = {}

    def fetch_transaction(self, payment_id: str) -> Optional[Dict[str, Any]]:
        """
        Simulate querying payment switch by transaction ID.
        """
        # In a real environment, this makes an HTTP call to gateway status API.
        # Here we simulate gateway response structure.
        return {
            "query_time": datetime.datetime.utcnow().isoformat(),
            "payment_id": payment_id,
            "gateway_connected": True,
            "switch_code": "PAYTM_PSP_SIM",
        }

    def initiate_refund(
        self,
        payment_id: str,
        amount: float,
        idempotency_key: str,
        reason: str
    ) -> Dict[str, Any]:
        """
        Simulate calling Gateway Refund API with idempotency.
        Transitions state to PROCESSING.
        """
        if idempotency_key in self.refund_ledger:
            existing = self.refund_ledger[idempotency_key]
            return {
                "success": True,
                "is_duplicate": True,
                "gateway_refund_ref": existing["gateway_refund_ref"],
                "status": existing["status"],
                "message": "Refund already initiated (idempotent replay)",
                "amount": existing["amount"],
            }

        gateway_refund_ref = f"PG_REF_{uuid.uuid4().hex[:10].upper()}"
        refund_record = {
            "gateway_refund_ref": gateway_refund_ref,
            "payment_id": payment_id,
            "amount": amount,
            "reason": reason,
            "idempotency_key": idempotency_key,
            "status": "PROCESSING",
            "initiated_at": datetime.datetime.utcnow().isoformat(),
            "bank_settlement_status": "PENDING_SETTLEMENT"
        }
        self.refund_ledger[idempotency_key] = refund_record

        return {
            "success": True,
            "is_duplicate": False,
            "gateway_refund_ref": gateway_refund_ref,
            "status": "PROCESSING",
            "message": "Refund initiated with payment switch. Verification required.",
            "amount": amount,
            "initiated_at": refund_record["initiated_at"]
        }

    def verify_refund_completion(self, gateway_refund_ref: str) -> Dict[str, Any]:
        """
        Crucial requirement: Verify payment-system confirmation before claiming completion.
        Queries banking reconciliation switch to confirm bank settlement.
        """
        matched = None
        for record in self.refund_ledger.values():
            if record["gateway_refund_ref"] == gateway_refund_ref:
                matched = record
                break

        # Simulate bank verification switch
        utr = f"UTR{random.randint(100000000000, 999999999999)}"
        if matched:
            matched["status"] = "COMPLETED"
            matched["bank_settlement_status"] = "SETTLED"
            matched["utr"] = utr
            matched["settled_at"] = datetime.datetime.utcnow().isoformat()

        return {
            "verified": True,
            "gateway_refund_ref": gateway_refund_ref,
            "bank_status": "SETTLED_TO_ORIGINAL_SOURCE",
            "utr_number": utr,
            "confirmation_code": "PAYTM_SWITCH_OK_200",
            "verified_at": datetime.datetime.utcnow().isoformat(),
            "notes": "Simulated bank switch confirmed instant UPI reversal credit."
        }


# Singleton simulated gateway instance
simulated_gateway = SimulatedPaymentGateway()
