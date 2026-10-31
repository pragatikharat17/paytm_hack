# AtlasAI — Autonomous AI Customer Resolution Teammate

**Paytm Build for India AI Hackathon 2026 · Track 3: Autonomous AI Teammates**

> **"Never make customers wait for refunds. Never let AI act without deterministic policy guardrails."**

AtlasAI is a production-inspired, autonomous customer resolution teammate designed for digital payment ecosystems. It investigates failed payments, missing refunds, and transaction disputes across **English, Hindi, and Marathi**, combines multi-agent reasoning with deterministic policy rules, executes and verifies simulated payment settlements, and escalates sensitive edge cases to human supervisors with a complete audit trail.

---

## 🌟 Executive Summary

In digital payments, automated chatbots frequently give canned, non-committal answers ("Please wait 3-5 business days") while customers remain anxious about debited funds.

AtlasAI changes this by functioning as an **Autonomous AI Teammate**, capable of:
1. Ingesting spoken or typed complaints in **Hindi, Marathi, and English** via **Sarvam AI**.
2. Querying core switch records and simulated payment gateway APIs.
3. Evaluating deterministic refund policies (e.g. ₹1,000 autonomous refund limit, duplicate detection, fraud risk).
4. Executing simulated payment reversals and **verifying settlement confirmation** before claiming success.
5. Pausing high-value transactions for **one-click supervisor sign-off** in a React Admin Operations Portal.
6. Maintaining an immutable cryptographic audit trail of every agent action and tool call.

---

## 🏗️ Multi-Agent Architecture

```
                       CUSTOMER INTERFACE (Flutter / Web / Android)
                     [Voice / Text in English, Hindi, or Marathi]
                                         │
                                         ▼
                     SARVAM AI ENGINE (STT / Translation / TTS)
                                         │
                                         ▼
                   ┌───────────────────────────────────────────┐
                   │        AGENT 1: ORCHESTRATOR AGENT        │
                   │  - Intent & Language Classification       │
                   │  - Entity & Payment ID Extraction         │
                   │  - Multi-Agent Workflow State Machine     │
                   └─────────────────────┬─────────────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
┌──────────────────┐           ┌──────────────────┐            ┌──────────────────┐
│     AGENT 2:     │           │     AGENT 3:     │            │     AGENT 5:     │
│TRANSACTION AGENT │           │POLICY & RISK AGENT│           │CASE MEMORY AGENT │
│- Bank Debit Check│           │- ₹1,000 Limit    │            │- Duplicate Guard │
│- Gateway Switch  │           │- Fraud Indicators│            │- Case History    │
│- Core Ledger     │           │- Admin Escalation│            │- Playbook Memory │
└────────┬─────────┘           └─────────┬────────┘            └────────┬─────────┘
         │                               │                              │
         └───────────────────────────────┼──────────────────────────────┘
                                         ▼
                   ┌───────────────────────────────────────────┐
                   │        AGENT 4: RESOLUTION AGENT          │
                   │  - Executes Permitted Simulated Refunds   │
                   │  - Verifies Settlement Switch UTR         │
                   │  - Creates Tier-2 Fraud Dispute Tickets   │
                   │  - Generates Multilingual Audio Synthesis │
                   └─────────────────────┬─────────────────────┘
                                         │
                  ┌──────────────────────┴──────────────────────┐
                  ▼                                             ▼
       [Outcomes: AUTO_RESOLVED]                    [SUPERVISOR PORTAL]
     Instant Settlement Confirmed                High-Value Approval Queue
```

### Specialized Agents

| Agent | Core Responsibility | Deterministic Tooling |
|---|---|---|
| **Agent 1: Orchestrator** | Accepts complaints, identifies language & intent, coordinates pipeline. | Sarvam NLU, regex parser, state machine. |
| **Agent 2: Transaction** | Retrieves payment & order records; checks if bank debited & switch dropped. | `SimulatedPaymentGateway.get_payment()` |
| **Agent 3: Policy & Risk** | Evaluates business rules, limits (₹1,000 threshold), and fraud indicators. | `PolicyEngine.evaluate()` |
| **Agent 4: Resolution** | Initiates refunds, verifies settlement confirmation, or files tickets. | `SimulatedPaymentGateway.initiate_refund()` |
| **Agent 5: Case Memory** | Prevents duplicate refund claims, retrieves history and precedents. | SQLite query cache & playbook hashing |
| **Learning Agent** | Captures successful human-approved supervisor resolutions into reusable playbooks. | `ResolutionPlaybook` store |

> [!IMPORTANT]
> **Critical Architecture Rule:** LLMs interpret, classify, summarize, and translate. **Refund authorizations, limit checks, and state changes are strictly enforced by deterministic Python backend rules.**

---

## 🎯 The 4 Tested Demo Scenarios

| Scenario | Customer Complaint | Payment ID & Amount | Autonomous Action & Outcome |
|---|---|---|---|
| **A: Auto-Refund** | *"₹499 was deducted, but my payment failed."* | `PAY1001` (₹499.00) | **AUTO_RESOLVED**: Bank debit verified, amount < ₹1,000 limit, instant simulated reversal executed with bank UTR. |
| **B: Human Approval** | *"My ₹1,299 payment failed. I haven't received my refund."* | `PAY1002` (₹1,299.00) | **PENDING_APPROVAL**: Amount exceeds ₹1,000 autonomous threshold. Pauses in Supervisor Approval Queue for 1-click admin sign-off. |
| **C: Fraud Dispute** | *"I don't recognize this ₹899 transaction. This might be fraud!"* | `PAY1003` (₹899.00) | **ESCALATED**: Risk score exceeds automated limit. Autonomous refund blocked; priority Tier-2 ticket `TKT_xxx` created. |
| **D: Multilingual Voice** | Marathi / Hindi speech: *"माझे ₹499 कट झाले पण पेमेंट अयशस्वी झाले."* | `PAY1001` (₹499.00) | **MULTILINGUAL RESOLUTION**: Sarvam STT transcribes speech, normalizes to English for agents, translates to Marathi, and synthesizes audio via Sarvam Bulbul TTS. |

---

## 💻 Tech Stack

- **Backend**: Python 3.11+, FastAPI, SQLAlchemy ORM, SQLite, Pydantic v2, HTTPX.
- **AI & Voice**: Sarvam AI (`saarika:v2` STT, `bulbul:v1` TTS, Hindi/Marathi/English translation, conversational reasoning).
- **Customer Application**: Flutter 3.44+ (Dart 3.12+), Material 3, Dark Navy & Electric Teal fintech design, Audio playback via `audioplayers`.
- **Admin Operations Dashboard**: React 18, Vite, Tailwind CSS, Lucide icons, responsive desktop-first layout.

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- Python 3.10+
- Node.js 18+ & npm
- Flutter 3.20+ (for mobile/web customer app)

---

### 2. Backend Setup & Test Suite
```bash
cd atlasai_backend

# 1. Install dependencies
pip install -r requirements.txt

# 2. Run automated test suite (Tests Scenarios A, B, C, D & Policy Guardrails)
python3 test_atlasai_pipeline.py

# 3. Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- Backend API Docs (Swagger): `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

---

### 3. React Admin Operations Dashboard
```bash
cd atlasai_admin

# 1. Install packages
npm install

# 2. Start Vite dev server
npm run dev
```
Open `http://localhost:5173` to access:
- **Operations Overview**: Real-time KPI cards & multi-agent mesh.
- **Supervisor Approvals**: Review high-value cases (e.g. `PAY1002` ₹1,299) and Approve/Reject with 1 click.
- **Case Evidence Drawer**: Inspect payment switch logs, multi-agent reasoning, and audit logs.
- **Demo Scenario Runner**: 1-click execution of Scenarios A, B, C, D directly from the admin panel.

---

### 4. Customer Flutter Application
```bash
cd atlasai_app

# 1. Verify dependencies & analyze code
flutter analyze

# 2. Run Flutter app on Web, Android, or Linux
flutter run -d chrome
# or on Android device/emulator:
# flutter run -d android
```

---

## 📊 Database Schema & Demo Records

The SQLite database seeds automatically on startup with fictional demo payments:

| Payment ID | Order ID | Amount | Switch Status | Bank Status | Scenario Covered |
|---|---|---|---|---|---|
| `PAY1001` | `ORD2001` | ₹499.00 | `FAILED` | `DEBITED` | Eligible for autonomous refund |
| `PAY1002` | `ORD2002` | ₹1,299.00 | `FAILED` | `DEBITED` | Requires supervisor approval (> ₹1,000) |
| `PAY1003` | `ORD2003` | ₹899.00 | `SUCCESS` | `DEBITED` | Unrecognized charge / Fraud escalation |
| `PAY1004` | `ORD2004` | ₹799.00 | `PENDING` | `DEBITED` | Pending investigation |

---

## 🛡️ Deterministic Refund State Machine

```
[REQUESTED]
     │
     ├── (Amount ≤ ₹1,000 & Safe) ──► [PROCESSING] ──► [COMPLETED] (Verified UTR)
     │
     ├── (Amount > ₹1,000) ──────────► [PENDING_APPROVAL]
     │                                        │
     │                           ┌────────────┴────────────┐
     │                           ▼                         ▼
     │                      [APPROVED]                [REJECTED]
     │                           │
     │                           ▼
     │                     [PROCESSING] ──► [COMPLETED]
     │
     └── (Fraud Indicator) ──────────► [ESCALATED] (Ticket Created)
```

No refund is marked `COMPLETED` without simulated payment switch verification.

---

## 👥 Hackathon Team & Acknowledgments
Built for **Paytm Build for India AI Hackathon 2026**
- Track 3: Autonomous AI Teammates
- Powered by **Sarvam AI** for Indian-language speech and translation.
