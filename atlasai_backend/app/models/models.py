import datetime
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    Text,
    ForeignKey,
    Index,
    JSON
)
from sqlalchemy.orm import relationship
from app.database import Base


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(String(50), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    email = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=False)
    upi_id = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    orders = relationship("Order", back_populates="customer")
    payments = relationship("Payment", back_populates="customer")
    complaints = relationship("Complaint", back_populates="customer")


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(50), unique=True, index=True, nullable=False)
    customer_id = Column(String(50), ForeignKey("customers.customer_id"), nullable=False)
    merchant_name = Column(String(100), nullable=False)
    amount = Column(Float, nullable=False)
    status = Column(String(50), nullable=False, default="PLACED")  # PLACED, FAILED, DELIVERED, CANCELLED, PENDING
    items_json = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    customer = relationship("Customer", back_populates="orders")
    payments = relationship("Payment", back_populates="order")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    payment_id = Column(String(50), unique=True, index=True, nullable=False)
    order_id = Column(String(50), ForeignKey("orders.order_id"), nullable=False)
    customer_id = Column(String(50), ForeignKey("customers.customer_id"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="INR")
    method = Column(String(50), default="UPI")  # UPI, WALLET, NETBANKING, CARD
    status = Column(String(50), nullable=False, default="PENDING")  # FAILED, SUCCESS, PENDING, REVERSED
    bank_ref = Column(String(100), nullable=True)
    gateway_status = Column(String(50), nullable=False, default="PENDING")  # FAILED, SUCCESS, PENDING
    bank_status = Column(String(50), nullable=False, default="DEBITED")  # DEBITED, NOT_DEBITED, REVERSED
    error_code = Column(String(50), nullable=True)
    failure_reason = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    customer = relationship("Customer", back_populates="payments")
    order = relationship("Order", back_populates="payments")
    complaints = relationship("Complaint", back_populates="payment")
    refund_requests = relationship("RefundRequest", back_populates="payment")


class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True, index=True)
    complaint_id = Column(String(50), unique=True, index=True, nullable=False)
    customer_id = Column(String(50), ForeignKey("customers.customer_id"), nullable=True)
    payment_id = Column(String(50), ForeignKey("payments.payment_id"), nullable=True)
    raw_text = Column(Text, nullable=False)
    original_language = Column(String(20), default="en")
    translated_text = Column(Text, nullable=True)
    intent = Column(String(100), nullable=True)
    status = Column(
        String(50),
        default="NEW"
    )  # NEW, INVESTIGATING, AUTO_RESOLVED, PENDING_APPROVAL, APPROVED, REJECTED, ESCALATED
    resolution_summary = Column(Text, nullable=True)
    audio_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    customer = relationship("Customer", back_populates="complaints")
    payment = relationship("Payment", back_populates="complaints")
    refund_requests = relationship("RefundRequest", back_populates="complaint")
    approval_requests = relationship("ApprovalRequest", back_populates="complaint")
    support_tickets = relationship("SupportTicket", back_populates="complaint")
    agent_decisions = relationship("AgentDecision", back_populates="complaint")


class RefundRequest(Base):
    __tablename__ = "refund_requests"

    id = Column(Integer, primary_key=True, index=True)
    refund_id = Column(String(50), unique=True, index=True, nullable=False)
    payment_id = Column(String(50), ForeignKey("payments.payment_id"), nullable=False)
    complaint_id = Column(String(50), ForeignKey("complaints.complaint_id"), nullable=True)
    amount = Column(Float, nullable=False)
    status = Column(
        String(50),
        default="REQUESTED"
    )  # REQUESTED, PENDING_APPROVAL, APPROVED, PROCESSING, COMPLETED, REJECTED, FAILED
    reason = Column(String(255), nullable=False)
    idempotency_key = Column(String(100), unique=True, index=True, nullable=False)
    gateway_refund_ref = Column(String(100), nullable=True)
    approved_by = Column(String(100), nullable=True)
    failure_reason = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    payment = relationship("Payment", back_populates="refund_requests")
    complaint = relationship("Complaint", back_populates="refund_requests")
    approval_requests = relationship("ApprovalRequest", back_populates="refund_request")


class ApprovalRequest(Base):
    __tablename__ = "approval_requests"

    id = Column(Integer, primary_key=True, index=True)
    approval_id = Column(String(50), unique=True, index=True, nullable=False)
    complaint_id = Column(String(50), ForeignKey("complaints.complaint_id"), nullable=False)
    refund_id = Column(String(50), ForeignKey("refund_requests.refund_id"), nullable=True)
    amount = Column(Float, nullable=False)
    reason = Column(Text, nullable=False)
    risk_score = Column(Float, default=0.0)
    required_role = Column(String(50), default="SUPPORT_LEAD")
    status = Column(String(50), default="PENDING")  # PENDING, APPROVED, REJECTED
    admin_notes = Column(Text, nullable=True)
    decided_by = Column(String(100), nullable=True)
    decided_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    complaint = relationship("Complaint", back_populates="approval_requests")
    refund_request = relationship("RefundRequest", back_populates="approval_requests")


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(String(50), unique=True, index=True, nullable=False)
    complaint_id = Column(String(50), ForeignKey("complaints.complaint_id"), nullable=True)
    customer_id = Column(String(50), nullable=True)
    payment_id = Column(String(50), nullable=True)
    priority = Column(String(20), default="MEDIUM")  # LOW, MEDIUM, HIGH, CRITICAL
    category = Column(String(50), nullable=False)  # FRAUD_DISPUTE, TRANSACTION_PENDING, TECH_ISSUE
    subject = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(50), default="OPEN")  # OPEN, IN_PROGRESS, RESOLVED
    assigned_to = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    complaint = relationship("Complaint", back_populates="support_tickets")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    case_id = Column(String(50), index=True, nullable=False)  # complaint_id or payment_id
    event_type = Column(String(50), nullable=False)
    actor = Column(String(50), nullable=False)  # SYSTEM, AGENT_ORCHESTRATOR, AGENT_TRANSACTION, AGENT_POLICY, AGENT_RESOLUTION, ADMIN, CUSTOMER
    action = Column(String(100), nullable=False)
    details = Column(JSON, nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)


class AgentDecision(Base):
    __tablename__ = "agent_decisions"

    id = Column(Integer, primary_key=True, index=True)
    complaint_id = Column(String(50), ForeignKey("complaints.complaint_id"), index=True, nullable=False)
    agent_name = Column(String(50), nullable=False)
    decision = Column(String(100), nullable=False)
    confidence = Column(Float, default=1.0)
    reasoning = Column(Text, nullable=False)
    evidence = Column(JSON, nullable=True)
    tools_called = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    complaint = relationship("Complaint", back_populates="agent_decisions")


class ResolutionPlaybook(Base):
    __tablename__ = "resolution_playbooks"

    id = Column(Integer, primary_key=True, index=True)
    pattern_hash = Column(String(100), unique=True, index=True, nullable=False)
    scenario_name = Column(String(100), nullable=False)
    intent = Column(String(100), nullable=False)
    conditions = Column(JSON, nullable=False)
    recommended_action = Column(String(100), nullable=False)
    success_count = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
