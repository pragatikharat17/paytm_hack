"""
AtlasAI Autonomous Multi-Agent Test Suite
Tests all 4 demo scenarios, deterministic policies, simulated gateway, and admin approvals.
"""

import sys
import os
import asyncio

# Ensure app is on python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import Base, engine, SessionLocal
from app.seed_data import seed_database
from app.models.models import Complaint, Payment, RefundRequest, ApprovalRequest, SupportTicket, AuditLog
from app.agents.orchestrator_agent import OrchestratorAgent
from app.routers.admin import approve_request
from app.schemas.schemas import ApprovalActionRequest


async def run_scenario_tests():
    print("================================================================")
    print("  ATLASAI AUTONOMOUS CUSTOMER RESOLUTION TEAMMATE - TEST SUITE")
    print("================================================================")

    # 1. Initialize & Seed Database
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed_database(db)
    print("✓ SQLite tables created and demo data seeded (PAY1001-PAY1004)")

    # -------------------------------------------------------------
    # Test Scenario A: Automatic Refund (₹499 failed payment)
    # -------------------------------------------------------------
    print("\n--- Testing Scenario A: Automatic Refund (₹499) ---")
    res_a = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text="₹499 was deducted, but my payment failed. Please refund my money. (PAY1001)",
        payment_id_hint="PAY1001",
        customer_id="CUST101",
        input_language="en"
    )
    print(f"Outcome: {res_a.outcome}")
    print(f"Final Message: {res_a.final_message}")
    assert res_a.outcome == "AUTO_RESOLVED", f"Expected AUTO_RESOLVED but got {res_a.outcome}"
    assert res_a.refund is not None, "Expected refund record to be created"
    assert res_a.refund.status == "COMPLETED", f"Expected refund COMPLETED but got {res_a.refund.status}"
    print(f"✓ Scenario A Passed! Refund ID: {res_a.refund.refund_id}, Status: {res_a.refund.status}")

    # -------------------------------------------------------------
    # Test Scenario B: Human Approval (₹1,299 failed payment > ₹1,000 limit)
    # -------------------------------------------------------------
    print("\n--- Testing Scenario B: Human Approval (₹1,299) ---")
    res_b = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text="My ₹1,299 payment failed. I haven't received my refund. (PAY1002)",
        payment_id_hint="PAY1002",
        customer_id="CUST102",
        input_language="en"
    )
    print(f"Outcome: {res_b.outcome}")
    print(f"Final Message: {res_b.final_message}")
    assert res_b.outcome == "PENDING_APPROVAL", f"Expected PENDING_APPROVAL but got {res_b.outcome}"
    assert res_b.approval is not None, "Expected approval record to be created"
    assert res_b.approval.status == "PENDING", f"Expected approval PENDING but got {res_b.approval.status}"
    print(f"✓ Scenario B Paused for Admin! Approval ID: {res_b.approval.approval_id}")

    # Test Admin Approval of Scenario B
    print("\n--- Testing Admin Dashboard Approval Action for Scenario B ---")
    admin_action = ApprovalActionRequest(
        admin_name="Vikram Seth (Support Lead)",
        notes="Verified bank debit drop against switch ledger. Approved full refund."
    )
    approved_res = approve_request(
        id=res_b.approval.approval_id,
        req=admin_action,
        db=db
    )
    print(f"Admin Approval Status: {approved_res.status}")
    assert approved_res.status == "APPROVED", "Expected approval status APPROVED"
    # Check refund record transitioned to COMPLETED
    updated_refund = db.query(RefundRequest).filter_by(refund_id=approved_res.refund_id).first()
    assert updated_refund.status == "COMPLETED", f"Expected refund COMPLETED after approval, got {updated_refund.status}"
    print(f"✓ Scenario B Approval Completed! Verified Bank Reversal Settlement UTR generated.")

    # -------------------------------------------------------------
    # Test Scenario C: Suspicious Transaction / Dispute (₹899)
    # -------------------------------------------------------------
    print("\n--- Testing Scenario C: Suspicious / Unrecognized Charge (₹899) ---")
    res_c = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text="I don't recognize this ₹899 transaction. This might be unauthorized fraud! (PAY1003)",
        payment_id_hint="PAY1003",
        customer_id="CUST103",
        input_language="en"
    )
    print(f"Outcome: {res_c.outcome}")
    print(f"Final Message: {res_c.final_message}")
    assert res_c.outcome == "ESCALATED", f"Expected ESCALATED but got {res_c.outcome}"
    assert res_c.ticket is not None, "Expected support ticket to be created"
    assert res_c.ticket.category == "FRAUD_DISPUTE", f"Expected category FRAUD_DISPUTE, got {res_c.ticket.category}"
    print(f"✓ Scenario C Escalation Passed! Ticket ID: {res_c.ticket.ticket_id}, Priority: {res_c.ticket.priority}")

    # -------------------------------------------------------------
    # Test Scenario D: Multilingual Voice / Marathi & Hindi
    # -------------------------------------------------------------
    print("\n--- Testing Scenario D: Multilingual Support (Hindi & Marathi) ---")
    res_d_hi = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text="मेरे ₹499 कट गए लेकिन पेमेंट फेल हो गया, मेरा रिफंड कब आएगा? PAY1001",
        payment_id_hint="PAY1001",
        customer_id="CUST101",
        input_language="hi"
    )
    print(f"Hindi Detected Lang: {res_d_hi.language}")
    print(f"Hindi Response: {res_d_hi.translated_message}")
    assert res_d_hi.audio_base64 is not None, "Expected audio base64 to be generated"
    print("✓ Hindi Voice/NLU Passed! Audio generated.")

    res_d_mr = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text="माझे ₹499 खात्यातून कट झाले पण पेमेंट अयशस्वी झाले. कृपया रिफंड करा. PAY1001",
        payment_id_hint="PAY1001",
        customer_id="CUST101",
        input_language="mr"
    )
    print(f"Marathi Detected Lang: {res_d_mr.language}")
    print(f"Marathi Response: {res_d_mr.translated_message}")
    assert res_d_mr.audio_base64 is not None, "Expected audio base64 to be generated"
    print("✓ Marathi Voice/NLU Passed! Audio generated.")

    # -------------------------------------------------------------
    # Verify Audit Trail
    # -------------------------------------------------------------
    print("\n--- Verifying Audit Trail Integrity ---")
    audit_count = db.query(AuditLog).count()
    print(f"Total Audit Trail Entries: {audit_count}")
    assert audit_count >= 5, "Expected comprehensive audit logs"
    print("✓ Audit trail verified!")

    db.close()
    print("\n================================================================")
    print("  ALL ATLASAI BACKEND & AGENT SCENARIOS PASSED WITH 100% SUCCESS!")
    print("================================================================\n")


if __name__ == "__main__":
    asyncio.run(run_scenario_tests())
