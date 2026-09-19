# 01 — Dead Lead Reactivation

Finds cold leads sitting in a CRM, drafts a personalized re-engagement email for each one using a local AI model, runs every draft through an automated quality-control layer before sending, and handles the replies that come back — routing genuine interest to a human, snoozing bad timing, honoring unsubscribe requests, and ignoring autoresponders.

---

## What it does

**Workflow A — Reactivation Sequence**

1. Pulls dead/cold leads from Postgres, scored by deal value and days inactive
2. A local LLM (via LM Studio) drafts a personalized re-engagement email per lead, adapting the message angle based on how many times that lead has already been contacted
3. Every draft passes through an automated QC layer — checks length, tone, whether the lead's name was actually used, whether the subject line is well-formed — before anything is allowed to send
4. Drafts that fail QC are held back, never sent
5. Approved emails go out over SMTP, throttled to avoid provider rate limits
6. Each lead's status and touch count update in the database, and leads that hit 3 touches with no reply are automatically marked exhausted

**Workflow B — Reply Handler**

1. Polls the inbox for replies tagged to this campaign
2. Matches each reply back to the correct lead by email address
3. A local AI model classifies the reply's intent: interested, has a question, bad timing, not interested, wants to unsubscribe, or just an autoresponder
4. Routes accordingly:
   - **Interested / has a question** → alerts a human via Telegram, marks the lead as replied. No auto-reply — real interest gets a real response.
   - **Not right now** → snoozes the lead for 90 days, re-enters the sequence automatically later
   - **Not interested** → marks the lead exhausted, stops contact
   - **Unsubscribe** → marks the lead unsubscribed and adds them to a permanent suppression list, checked by Workflow A on every run
   - **Autoresponder / out-of-office** → ignored entirely, no state change
5. Classifications below a confidence threshold are routed to a human for manual review instead of being acted on automatically

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create this workflow's database

```bash
docker exec -it <postgres_container_name> psql -U n8n -c "CREATE DATABASE reactivation;"
```

### 2. Seed it

```bash
docker cp reactivation_seed.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d reactivation -f /tmp/reactivation_seed.sql
```

This creates `leads`, `suppression_list`, and `email_log`, and populates `leads` with 24 sample records covering every status and edge case (already exhausted, unsubscribed, mid-sequence, never contacted, apostrophes in names, missing fields, etc.) so the workflow can be tested end to end without real data.

### 3. Import the workflows

In n8n, import:

- `01 Dead Lead Reactivation.json`
- `01 Reply Handling.json`

### 4. Point credentials at this database

Both workflows' Postgres nodes need the shared Postgres credential, with **database** set to `reactivation`.

### 5. Gmail filter for reply routing

Create a Gmail label called `Reactivation`, and a filter matching `subject:([Reactivation])` that applies that label automatically. This is how Workflow B's IMAP trigger knows which incoming messages are replies to this campaign. The `[Reactivation]` subject prefix is added automatically by the workflow on every outgoing email.

### 6. Run it

Execute Workflow A manually from the trigger node to send a test batch, then reply to one of the sent emails to test Workflow B's classification and routing.

---

## Schema

```sql
leads (
  id, first_name, last_name, company, email, industry,
  last_purchase_date, last_contact_date, deal_value, lost_reason,
  status,            -- dead | in_reactivation | replied | exhausted | unsubscribed
  touch_count, next_touch_at,
  last_sent_subject, last_sent_body, replied_at
)

suppression_list ( email, reason, created_at )

email_log ( lead_id, touch_number, subject, body, validation_pass, validation_fail, sent_at )
```
