# 04 — Accounts Receivable and Payment Chasing

Finds overdue invoices sitting in a database, drafts a stage-appropriate follow-up email for each one using a local AI model, runs every draft through an automated guardrail that locks in the real financial facts before sending, and handles the replies that come back — rescheduling on genuine payment promises, flagging disputes and unverified payment claims for a human, and never auto-suppressing collection on a stop request.

---

## What it does

**Workflow A — Chase Sequence**

1. Pulls unpaid/reminded invoices from Postgres that are due or overdue and not disputed
2. Each invoice is scored into an escalation stage based on days overdue: 0 (due date, friendly), 1 (7+ days, polite nudge), 2 (21+ days, firm but respectful), 3 (45+ days, final stage)
3. Invoices at stage 3 skip the email entirely — a Telegram alert fires and the invoice is marked `escalated_human`, since anything this overdue needs a person, not another automated email
4. A local LLM (via LM Studio) drafts the email for stages 0–2, matching tone to stage. The invoice number, amount, currency, and due date are passed in as exact facts the model must use verbatim, never compute or restate
5. Every draft passes through an automated guardrail — checks length, that the invoice number and amount appear verbatim in the body, that no second dollar figure was invented, and that no collections/legal language or unauthorized terms (late fees, waivers, discounts) were added — before anything is allowed to send
6. Drafts that fail the guardrail are held back and alert a human, never sent
7. Approved emails go out over SMTP, throttled to avoid provider rate limits
8. Each invoice's status, escalation stage, and next action time update in the database after sending

**Workflow B — Reply Handler**

1. Polls the inbox for replies tagged to this campaign
2. Strips quoted history so only the actual reply text is classified
3. A local AI model classifies the reply's intent: payment promise, already paid, dispute, negotiation request, question, stop request, or autoresponder
4. If the reply is a payment promise, the promised day (e.g. "Friday") is extracted and resolved to a real calendar date in code — deliberately not left to the AI, since local models are unreliable at date arithmetic
5. Routes accordingly:
   - **Payment promise** → reschedules the next action to 2 days after the promised date, no human needed
   - **Already paid** → pauses the sequence and alerts a human to verify against actual bank/payment records. A claim of payment is never trusted automatically
   - **Dispute** → pauses the sequence, flags the invoice, and alerts a human immediately — the highest-priority case in the workflow
   - **Negotiation request** → pauses the sequence and alerts a human to set payment plan terms
   - **Question** → alerts a human to reply personally, no state change
   - **Stop request** → does **not** auto-suppress contact (unlike a marketing unsubscribe, you can't legally stop collecting on a genuine debt just because someone asks), logs the request, and alerts a human to review
   - **Autoresponder / out-of-office** → ignored entirely, no state change
6. Classifications below a confidence threshold are routed to a human for manual review instead of being acted on automatically

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create this workflow's database

```bash
docker exec -it <postgres_container_name> psql -U n8n -c "CREATE DATABASE accounts_receivable;"
```

### 2. Seed it

```bash
docker cp accounts_receivable_schema.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d accounts_receivable -f /tmp/accounts_receivable_schema.sql
```

This creates `invoices` and populates it with 4 sample records covering every escalation stage (not yet due, ~5 days overdue, ~15 days overdue, ~50 days overdue) so the workflow can be tested end to end without real data.

### 3. Import the workflows

In n8n, import:

- `AR — Chase Sequence (A).json`
- `AR — Reply Handling (B).json`

### 4. Point credentials at this database

Both workflows' Postgres nodes need the shared Postgres credential, with **database** set to `accounts_receivable`.

### 5. Gmail filter for reply routing

Create a Gmail label called `AR-Chase`, and a filter matching `subject:(AR-Chase)` that applies that label automatically. This is how Workflow B's IMAP trigger knows which incoming messages are replies to this campaign. The `[AR-Chase]` subject prefix is added automatically by the workflow on every outgoing email.

### 6. Run it

Execute Workflow A manually from the trigger node to send a test batch, then reply to one of the sent emails (try phrases like "I'll pay Friday," "already paid," or "I want to dispute this") to test Workflow B's classification and routing.

---

## Schema

```sql
invoices (
  id, client_name, company, email, invoice_number,
  amount, currency, issued_date, due_date,
  status,              -- unpaid | reminded | promised | disputed | negotiating | pending_verification | paid | escalated_human
  escalation_stage,    -- 0 | 1 | 2 | 3
  last_contact_date, next_action_at, last_sent_body,
  promised_pay_date, paid_at, dispute_flag, notes
)
```
