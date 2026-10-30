import datetime
from sqlalchemy.orm import Session
from app.models.models import Customer, Order, Payment, ResolutionPlaybook


def seed_database(db: Session):
    """
    Seeds database with fictional demo customers, orders, payments,
    and learning agent playbooks as per the hackathon requirements.
    """
    # 1. Customers
    existing_cust = db.query(Customer).filter_by(customer_id="CUST101").first()
    if not existing_cust:
        customers = [
            Customer(
                customer_id="CUST101",
                name="Rajesh Kumar",
                email="rajesh.kumar@example.com",
                phone="+919876543210",
                upi_id="rajesh@paytm",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=120)
            ),
            Customer(
                customer_id="CUST102",
                name="Priya Sharma",
                email="priya.sharma@example.com",
                phone="+919812345678",
                upi_id="priya@paytm",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=90)
            ),
            Customer(
                customer_id="CUST103",
                name="Amit Patel",
                email="amit.patel@example.com",
                phone="+919823456789",
                upi_id="amit@okhdfcbank",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=60)
            ),
            Customer(
                customer_id="CUST104",
                name="Sneha Patil",
                email="sneha.patil@example.com",
                phone="+919834567890",
                upi_id="sneha@oksbi",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=30)
            )
        ]
        db.add_all(customers)
        db.commit()

    # 2. Orders
    existing_order = db.query(Order).filter_by(order_id="ORD5001").first()
    if not existing_order:
        orders = [
            Order(
                order_id="ORD5001",
                customer_id="CUST101",
                merchant_name="Swiggy Food Delivery",
                amount=499.00,
                status="FAILED",
                items_json=[{"item": "Paneer Biryani Combo", "qty": 1, "price": 499.00}],
                created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=2)
            ),
            Order(
                order_id="ORD5002",
                customer_id="CUST102",
                merchant_name="Zomato Gourmet",
                amount=1299.00,
                status="FAILED",
                items_json=[{"item": "Family Meal Box & Desserts", "qty": 1, "price": 1299.00}],
                created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=4)
            ),
            Order(
                order_id="ORD5003",
                customer_id="CUST103",
                merchant_name="Flipkart Electronics",
                amount=899.00,
                status="DELIVERED",
                items_json=[{"item": "Wireless Bluetooth Earbuds", "qty": 1, "price": 899.00}],
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=1)
            ),
            Order(
                order_id="ORD5004",
                customer_id="CUST104",
                merchant_name="BookMyShow Movies",
                amount=799.00,
                status="PENDING",
                items_json=[{"item": "IMAX 3D Movie Tickets (2)", "qty": 1, "price": 799.00}],
                created_at=datetime.datetime.utcnow() - datetime.timedelta(minutes=30)
            )
        ]
        db.add_all(orders)
        db.commit()

    # 3. Payments
    existing_pay = db.query(Payment).filter_by(payment_id="PAY1001").first()
    if not existing_pay:
        payments = [
            Payment(
                payment_id="PAY1001",
                order_id="ORD5001",
                customer_id="CUST101",
                amount=499.00,
                currency="INR",
                method="UPI",
                status="FAILED",
                bank_ref="REF9901448821",
                gateway_status="FAILED",
                bank_status="DEBITED",
                error_code="GATEWAY_TIMEOUT",
                failure_reason="Gateway did not receive merchant ack within 30s. Customer account debited.",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=2)
            ),
            Payment(
                payment_id="PAY1002",
                order_id="ORD5002",
                customer_id="CUST102",
                amount=1299.00,
                currency="INR",
                method="UPI",
                status="FAILED",
                bank_ref="REF9901883344",
                gateway_status="FAILED",
                bank_status="DEBITED",
                error_code="SWITCH_COMMUNICATION_ERROR",
                failure_reason="Bank switch reported debit, but merchant drop occurred.",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=4)
            ),
            Payment(
                payment_id="PAY1003",
                order_id="ORD5003",
                customer_id="CUST103",
                amount=899.00,
                currency="INR",
                method="UPI",
                status="SUCCESS",
                bank_ref="REF9902551100",
                gateway_status="SUCCESS",
                bank_status="DEBITED",
                error_code=None,
                failure_reason=None,
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=1)
            ),
            Payment(
                payment_id="PAY1004",
                order_id="ORD5004",
                customer_id="CUST104",
                amount=799.00,
                currency="INR",
                method="UPI",
                status="PENDING",
                bank_ref="REF9903992211",
                gateway_status="PENDING",
                bank_status="DEBITED",
                error_code="PENDING_SETTLEMENT",
                failure_reason="Awaiting final clearance from issuing bank switch.",
                created_at=datetime.datetime.utcnow() - datetime.timedelta(minutes=30)
            )
        ]
        db.add_all(payments)
        db.commit()

    # 4. Initial Resolution Playbooks (for Case Memory / Learning Agent)
    existing_playbook = db.query(ResolutionPlaybook).filter_by(pattern_hash="FAILED_DEBIT_LEQ_1000").first()
    if not existing_playbook:
        playbooks = [
            ResolutionPlaybook(
                pattern_hash="FAILED_DEBIT_LEQ_1000",
                scenario_name="Failed Payment Small Ticket (< ₹1000)",
                intent="FAILED_PAYMENT_REFUND",
                conditions={"payment_status": "FAILED", "bank_status": "DEBITED", "max_amount": 1000.0},
                recommended_action="AUTO_REFUND",
                success_count=42,
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=10)
            ),
            ResolutionPlaybook(
                pattern_hash="FAILED_DEBIT_GT_1000",
                scenario_name="Failed Payment High Ticket (> ₹1000)",
                intent="FAILED_PAYMENT_REFUND",
                conditions={"payment_status": "FAILED", "bank_status": "DEBITED", "min_amount": 1000.0},
                recommended_action="REQUIRE_APPROVAL",
                success_count=18,
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=8)
            ),
            ResolutionPlaybook(
                pattern_hash="SUCCESS_UNRECOGNIZED",
                scenario_name="Successful Charge Unrecognized Dispute",
                intent="DISPUTE_UNRECOGNIZED_TRANSACTION",
                conditions={"payment_status": "SUCCESS", "fraud_flag": True},
                recommended_action="ESCALATE_TO_SUPPORT",
                success_count=25,
                created_at=datetime.datetime.utcnow() - datetime.timedelta(days=5)
            )
        ]
        db.add_all(playbooks)
        db.commit()
