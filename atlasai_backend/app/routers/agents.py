from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.schemas import AgentResolveRequest, AgentResolveResponse
from app.agents.orchestrator_agent import OrchestratorAgent

router = APIRouter(prefix="/api/agents", tags=["Autonomous Agents"])


@router.post("/resolve", response_model=AgentResolveResponse)
async def resolve_complaint(
    req: AgentResolveRequest,
    db: Session = Depends(get_db)
):
    """
    Autonomous multi-agent resolution entrypoint.
    Executes Orchestrator -> Transaction Agent -> Policy Agent -> Resolution Agent -> Voice Synthesis.
    """
    if not req.complaint_text.strip():
        raise HTTPException(status_code=400, detail="Complaint text cannot be empty")

    response = await OrchestratorAgent.process_complaint(
        db=db,
        complaint_text=req.complaint_text,
        payment_id_hint=req.payment_id,
        customer_id=req.customer_id or "CUST101",
        input_language=req.language or "en"
    )
    return response
