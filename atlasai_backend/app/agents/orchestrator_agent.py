"""
Agent 1: Orchestrator Agent
---------------------------
The master controller for AtlasAI autonomous resolution:
1. Normalizes input and extracts intent/entities (Sarvam AI / Groq / deterministic).
2. Consults CaseMemoryAgent for duplicates and context.
3. Dispatches TransactionAgent to retrieve real transaction & switch status.
4. Invokes PolicyRiskAgent to evaluate business rules & limits.
5. Directs ResolutionAgent to perform safe actions or request human approval.
6. Translates final decision into customer's native language (Hindi, Marathi, English).
7. Synthesizes voice audio via Sarvam TTS.
8. Records complete audit trails and agent decisions.
"""

import uuid
import datetime
from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session

from app.models.models import Complaint, AgentDecision
from app.schemas.schemas import AgentWorkflowStep, AgentResolveResponse
from app.services.sarvam_service import sarvam_service
from app.services.audit_service import AuditService
from app.agents.transaction_agent import TransactionAgent
from app.agents.memory_agent import CaseMemoryAgent
from app.agents.policy_agent import PolicyRiskAgent
from app.agents.resolution_agent import ResolutionAgent


class OrchestratorAgent:
    NAME = "OrchestratorAgent"

    @classmethod
    async def process_complaint(
        cls,
        db: Session,
        complaint_text: str,
        payment_id_hint: Optional[str] = None,
        customer_id: Optional[str] = "CUST101",
        input_language: Optional[str] = "en"
    ) -> AgentResolveResponse:
        workflow_steps: List[AgentWorkflowStep] = []

        # -------------------------------------------------------------
        # Step 1: Language & Intent Understanding (Sarvam AI)
        # -------------------------------------------------------------
        extraction = await sarvam_service.extract_intent_and_entities(complaint_text, input_language or "en")
        intent = extraction.get("intent", "GENERAL_PAYMENT_INQUIRY")
        extracted_pay_id = extraction.get("payment_id") or payment_id_hint
        
        # Detect or refine language
        detected_lang = input_language or "en"
        text_lower = complaint_text.lower()
        if any(w in text_lower for w in ["कट झाले", "पैसे गेले", "नाही आला", "तक्रार", "अडकले", "खात्यातून", "माझे"]):
            detected_lang = "mr"
        elif any(w in text_lower for w in ["कट गए", "रुपये", "पैसे", "रिफंड", "धोखा", "विफल", "खाते", "मेरे"]):
            detected_lang = "hi"

        step1 = AgentWorkflowStep(
            agent_name=cls.NAME,
            action="NLU_INTENT_EXTRACTION",
            status="SUCCESS",
            reasoning=f"Identified intent '{intent}' and target payment ID '{extracted_pay_id}'. Customer language: '{detected_lang}'.",
            evidence={
                "raw_text": complaint_text,
                "detected_language": detected_lang,
                "intent": intent,
                "extracted_payment_id": extracted_pay_id,
                "extracted_amount": extraction.get("amount"),
                "method": extraction.get("method")
            },
            tools_called=["sarvam_service.extract_intent_and_entities"],
            timestamp=datetime.datetime.utcnow()
        )
        workflow_steps.append(step1)

        # Create or find Complaint record
        complaint_id = f"CMP_{uuid.uuid4().hex[:8].upper()}"
        complaint = Complaint(
            complaint_id=complaint_id,
            customer_id=customer_id,
            payment_id=extracted_pay_id,
            raw_text=complaint_text,
            original_language=detected_lang,
            translated_text=complaint_text,
            intent=intent,
            status="INVESTIGATING"
        )
        db.add(complaint)
        db.commit()

        AuditService.log_event(
            db=db,
            case_id=complaint_id,
            event_type="COMPLAINT_RECEIVED",
            actor="CUSTOMER",
            action="SUBMIT_COMPLAINT",
            details={"raw_text": complaint_text, "intent": intent, "language": detected_lang}
        )

        # -------------------------------------------------------------
        # Step 2: Memory & Duplicate Check (CaseMemoryAgent)
        # -------------------------------------------------------------
        memory_result = CaseMemoryAgent.check_memory(
            db=db,
            payment_id=extracted_pay_id,
            customer_id=customer_id,
            intent=intent
        )
        step2 = AgentWorkflowStep(
            agent_name=CaseMemoryAgent.NAME,
            action="CHECK_CASE_MEMORY_AND_DUPLICATES",
            status="WARNING" if memory_result["has_duplicate_risk"] else "SUCCESS",
            reasoning=memory_result["reasoning"],
            evidence=memory_result["evidence"],
            tools_called=memory_result["tools_called"],
            timestamp=datetime.datetime.utcnow()
        )
        workflow_steps.append(step2)

        # -------------------------------------------------------------
        # Step 3: Transaction Investigation (TransactionAgent)
        # -------------------------------------------------------------
        txn_result = TransactionAgent.investigate(
            db=db,
            payment_id=extracted_pay_id,
            customer_id=customer_id
        )
        payment = txn_result["payment"]
        order = txn_result["order"]
        if payment and not complaint.payment_id:
            complaint.payment_id = payment.payment_id
            db.commit()

        step3 = AgentWorkflowStep(
            agent_name=TransactionAgent.NAME,
            action="RETRIEVE_PAYMENT_AND_ORDER_RECORDS",
            status="SUCCESS" if txn_result["success"] else "FAILED",
            reasoning=txn_result["reasoning"],
            evidence=txn_result["evidence"],
            tools_called=txn_result["tools_called"],
            timestamp=datetime.datetime.utcnow()
        )
        workflow_steps.append(step3)

        # -------------------------------------------------------------
        # Step 4: Policy & Risk Evaluation (PolicyRiskAgent)
        # -------------------------------------------------------------
        policy_result = PolicyRiskAgent.evaluate_policy(
            payment=payment,
            order=order,
            existing_refund=memory_result["existing_refund"],
            intent=intent,
            complaint_text=complaint_text
        )
        step4 = AgentWorkflowStep(
            agent_name=PolicyRiskAgent.NAME,
            action="EVALUATE_REFUND_POLICY_AND_RISK",
            status="WARNING" if policy_result["requires_human_approval"] else "SUCCESS",
            reasoning=policy_result["reasoning"],
            evidence=policy_result["evidence"],
            tools_called=policy_result["tools_called"],
            timestamp=datetime.datetime.utcnow()
        )
        workflow_steps.append(step4)

        # Record Agent Decision for Explainable AI
        agent_dec = AgentDecision(
            complaint_id=complaint_id,
            agent_name=PolicyRiskAgent.NAME,
            decision=policy_result["action"],
            confidence=0.98 if policy_result["eligible"] else 0.85,
            reasoning=policy_result["reasoning"],
            evidence=policy_result["evidence"],
            tools_called=policy_result["tools_called"]
        )
        db.add(agent_dec)
        db.commit()

        # -------------------------------------------------------------
        # Step 5: Resolution Execution (ResolutionAgent)
        # -------------------------------------------------------------
        resolution_result = ResolutionAgent.execute_resolution(
            db=db,
            complaint=complaint,
            payment=payment,
            order=order,
            policy_decision=policy_result
        )
        step5 = AgentWorkflowStep(
            agent_name=ResolutionAgent.NAME,
            action="EXECUTE_RESOLUTION_AND_VERIFY",
            status="SUCCESS" if resolution_result["outcome"] in ["AUTO_RESOLVED", "PENDING_APPROVAL"] else "ESCALATED",
            reasoning=resolution_result["reasoning"],
            evidence=resolution_result["evidence"],
            tools_called=resolution_result["tools_called"],
            timestamp=datetime.datetime.utcnow()
        )
        workflow_steps.append(step5)

        # -------------------------------------------------------------
        # Step 6: Multilingual Response & Speech Synthesis (Sarvam AI)
        # -------------------------------------------------------------
        english_message = resolution_result["final_message"]
        translated_message = english_message
        if detected_lang in ["hi", "mr", "hi-IN", "mr-IN"]:
            target_code = "hi-IN" if "hi" in detected_lang else "mr-IN"
            translated_message = await sarvam_service.translate_text(
                text=english_message,
                source_language_code="en-IN",
                target_language_code=target_code
            )

        # Synthesize speech
        audio_b64, audio_fmt = await sarvam_service.synthesize_speech(
            text=translated_message,
            language_code=detected_lang
        )

        return AgentResolveResponse(
            complaint_id=complaint.complaint_id,
            payment_id=payment.payment_id if payment else None,
            outcome=resolution_result["outcome"],
            final_message=english_message,
            translated_message=translated_message,
            language=detected_lang,
            workflow_steps=workflow_steps,
            refund=resolution_result.get("refund"),
            approval=resolution_result.get("approval"),
            ticket=resolution_result.get("ticket"),
            audio_base64=audio_b64
        )
