from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import Payment, Order
from app.schemas.schemas import PaymentResponse, OrderResponse

router = APIRouter(prefix="/api/payments", tags=["Payments"])


@router.get("", response_model=List[PaymentResponse])
def list_payments(
    customer_id: Optional[str] = None,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    query = db.query(Payment)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    return query.order_by(Payment.created_at.desc()).limit(limit).all()


@router.get("/{payment_id}", response_model=PaymentResponse)
def get_payment(payment_id: str, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter_by(payment_id=payment_id.upper()).first()
    if not payment:
        raise HTTPException(status_code=404, detail=f"Payment {payment_id} not found")
    return payment


@router.get("/{payment_id}/order", response_model=OrderResponse)
def get_payment_order(payment_id: str, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter_by(payment_id=payment_id.upper()).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    order = db.query(Order).filter_by(order_id=payment.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found for this payment")
    return order
