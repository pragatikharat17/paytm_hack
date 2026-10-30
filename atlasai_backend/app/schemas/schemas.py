import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


# Customer & Order
class CustomerBase(BaseModel):
    customer_id: str
    name: str
    email: Optional[str] = None
    phone: str
    upi_id: Optional[str] = None


class CustomerResponse(CustomerBase):
    id: int
    created_at: datetime.datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    order_id: str
    customer_id: str
    merchant_name: str
    amount: float
    status: str
    items_json: Optional[Any] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True


# Payment
class PaymentResponse(BaseModel):
    id: int
    payment_id: str
    order_id: str
    customer_id: str
    amount: float
    currency: str
    method: str
    status: str
    bank_ref: Optional[str] = None
    gateway_status: str
    bank_status: str
    error_code: Optional[str] = None
    failure_reason: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True


# Complaint
class ComplaintCreate(BaseModel):
    raw_text: str
    customer_id: Optional[str] = "CUST101"
    payment_id: Optional[str] = None
    language: Optional[str] = "en"


class ComplaintResponse(BaseModel):
    id: int
    complaint_id: str
    customer_id: Optional[str] = None
    payment_id: Optional[str] = None
    raw_text: str
    original_language: str
    translated_text: Optional[str] = None
    intent: Optional[str] = None
    status: str
    resolution_summary: Optional[str] = None
    audio_url: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True


# Refund
class RefundCreate(BaseModel):
    payment_id: str
    complaint_id: Optional[str] = None
    amount: float
    reason: str
    idempotency_key: Optional[str] = None


class RefundResponse(BaseModel):
    id: int
    refund_id: str
    payment_id: str
    complaint_id: Optional[str] = None
    amount: float
    status: str
    reason: str
    idempotency_key: str
    gateway_refund_ref: Optional[str] = None
    approved_by: Optional[str] = None
    failure_reason: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True


# Approval
class ApprovalActionRequest(BaseModel):
    admin_name: str = "Admin Operator"
    notes: Optional[str] = None


class ApprovalResponse(BaseModel):
    id: int
    approval_id: str
    complaint_id: str
    refund_id: Optional[str] = None
    amount: float
    reason: str
    risk_score: float
    required_role: str
    status: str
    admin_notes: Optional[str] = None
    decided_by: Optional[str] = None
    decided_at: Optional[datetime.datetime] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True


# Support Ticket
class SupportTicketResponse(BaseModel):
    id: int
    ticket_id: str
    complaint_id: Optional[str] = None
    customer_id: Optional[str] = None
    payment_id: Optional[str] = None
    priority: str
    category: str
    subject: str
    description: str
    status: str
    assigned_to: Optional[str] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True


# Audit Log
class AuditLogResponse(BaseModel):
    id: int
    case_id: str
    event_type: str
    actor: str
    action: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime.datetime

    class Config:
        from_attributes = True


# Agent Decision & Workflow
class AgentDecisionResponse(BaseModel):
    id: int
    complaint_id: str
    agent_name: str
    decision: str
    confidence: float
    reasoning: str
    evidence: Optional[Dict[str, Any]] = None
    tools_called: Optional[List[str]] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True


class AgentWorkflowStep(BaseModel):
    agent_name: str
    action: str
    status: str  # SUCCESS, WARNING, ESCALATED, FAILED
    reasoning: str
    evidence: Optional[Dict[str, Any]] = None
    tools_called: Optional[List[str]] = None
    timestamp: Optional[datetime.datetime] = None


class AgentResolveRequest(BaseModel):
    complaint_text: str
    payment_id: Optional[str] = None
    customer_id: Optional[str] = "CUST101"
    language: Optional[str] = "en"
    audio_base64: Optional[str] = None


class AgentResolveResponse(BaseModel):
    complaint_id: str
    payment_id: Optional[str] = None
    outcome: str  # AUTO_RESOLVED, PENDING_APPROVAL, ESCALATED, REJECTED, UNKNOWN
    final_message: str
    translated_message: str
    language: str
    workflow_steps: List[AgentWorkflowStep]
    refund: Optional[RefundResponse] = None
    approval: Optional[ApprovalResponse] = None
    ticket: Optional[SupportTicketResponse] = None
    audio_base64: Optional[str] = None
    audio_url: Optional[str] = None


# Voice Transcribe & Synthesize
class TranscribeResponse(BaseModel):
    transcript: str
    detected_language: str
    confidence: float = 1.0


class SynthesizeRequest(BaseModel):
    text: str
    language_code: str = "en-IN"  # hi-IN, mr-IN, en-IN
    speaker: Optional[str] = "meera"


class SynthesizeResponse(BaseModel):
    audio_base64: str
    format: str = "wav"


# Admin Case Details
class AdminCaseDetail(BaseModel):
    complaint: ComplaintResponse
    customer: Optional[CustomerResponse] = None
    payment: Optional[PaymentResponse] = None
    order: Optional[OrderResponse] = None
    refund: Optional[RefundResponse] = None
    approval: Optional[ApprovalResponse] = None
    ticket: Optional[SupportTicketResponse] = None
    audit_logs: List[AuditLogResponse] = []
    agent_decisions: List[AgentDecisionResponse] = []


class AdminKPIResponse(BaseModel):
    total_complaints: int
    resolved_cases: int
    pending_approvals: int
    escalated_cases: int
    total_refund_amount: float
