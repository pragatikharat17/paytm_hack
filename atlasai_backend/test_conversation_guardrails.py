import unittest
from unittest.mock import AsyncMock, MagicMock, patch

from app.agents.orchestrator_agent import OrchestratorAgent
from app.agents.resolution_agent import ResolutionAgent
from app.models.models import Complaint
from app.services.sarvam_service import sarvam_service


class ConversationTests(unittest.IsolatedAsyncioTestCase):
    async def test_clarifications_have_no_database_side_effects(self):
        cases = [
            ('hello', 'GENERAL_PAYMENT_INQUIRY', None),
            ('hello', 'GENERAL_INQUIRY', 'PAY1001'),
            ('refund my money', 'FAILED_PAYMENT_REFUND', None),
            ('what happened?', 'GENERAL_INQUIRY', None),
        ]
        for text, intent, hint in cases:
            with self.subTest(text=text, hint=hint):
                db = MagicMock()
                # An invented LLM payment ID must not select a transaction.
                extraction = {'intent': intent, 'payment_id': 'PAY9999'}
                with patch.object(sarvam_service, 'extract_intent_and_entities',
                                  AsyncMock(return_value=extraction)):
                    result = await OrchestratorAgent.process_complaint(
                        db, text, payment_id_hint=hint)
                self.assertEqual(result.outcome, 'INFO_ONLY')
                self.assertIsNone(result.complaint_id)
                self.assertIsNone(result.ticket)
                self.assertIsNone(result.refund)
                self.assertEqual(db.mock_calls, [])

    async def test_real_hello_classification_is_conversational(self):
        with patch.object(sarvam_service, 'groq_api_key', ''):
            result = await OrchestratorAgent.process_complaint(MagicMock(), 'hello')
        self.assertEqual(result.outcome, 'INFO_ONLY')


class EscalationTests(unittest.TestCase):
    def test_fraud_category_requires_fraud_evidence(self):
        for fraud, score, category in [(False, 0.7, 'PAYMENT_INVESTIGATION'),
                                       (True, 0.05, 'FRAUD_DISPUTE')]:
            with self.subTest(fraud=fraud):
                complaint = Complaint(complaint_id='TEST', customer_id='CUST101')
                policy = {'action': 'ESCALATE', 'risk_score': score, 'reason': 'Review required',
                          'evidence': {'rules_evaluated': {'fraud_trigger': fraud}}}
                with patch('app.agents.resolution_agent.AuditService.log_event'):
                    result = ResolutionAgent.execute_resolution(
                        MagicMock(), complaint, None, None, policy)
                self.assertEqual(result['ticket'].category, category)
