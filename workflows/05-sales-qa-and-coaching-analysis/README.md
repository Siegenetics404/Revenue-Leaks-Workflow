# 05 — Sales Call QA and Coaching Analysis

Scores every sales call against a rubric using a local AI model, verifies every evidence quote against the real transcript before trusting a score, flags calls that need coaching, and rolls scored calls into a weekly per-rep digest that tracks trend over time instead of a one-off report card.

---

## What it does

**Workflow A — Call Scoring**

1. A webhook receives a call transcript (speaker-labeled turns from Zoom, Google Meet, or a dialer) along with rep, customer, company, and date metadata
2. The rep's lines are pulled out and trimmed to an excerpt built from the opening, closing, and any turn containing objection language (price, competitor, "not sure," etc.), so a long call still fits the local model's context window
3. The raw call is inserted into Postgres with `status = 'pending_scoring'` before scoring runs, so a failed run still leaves a row to retry
4. A local LLM (via LM Studio) scores the rep across five categories — discovery, objection handling, value framing, next steps, tone — each 1–5, with a one-sentence coaching note and a verbatim evidence quote per category
5. Every score passes through an automated guardrail — checks the score is a valid 1–5, and that every evidence quote actually appears word-for-word in the real transcript. A quote the model invents or paraphrases is rejected outright
6. Calls that fail the guardrail are held back, alert a human, and are marked `needs_review` — never written to a rep's record unverified
7. Calls that pass are marked `scored`, with `coaching_needed` set true if the overall score is low or either objection handling or next steps scores 2 or below
8. Coaching-flagged calls trigger a manager alert naming the specific weak category and its exact quote, not just a number

**Workflow B — Coaching Digest**

1. Runs on a weekly schedule
2. Pulls every call scored in the last 7 days, and separately pulls the 7 days before that, both grouped by rep
3. For each rep, computes this week's average, last week's average, the trend, and the single weakest-scoring moment (with its quote) across the week's calls
4. Loops through reps one at a time — a local model handles one request at a time, so calls are processed sequentially, not in parallel
5. A local LLM drafts a short coaching note per rep, grounded only in the stats and the one weakest quote it's given — never invents a call detail or number
6. Each note passes through a guardrail checking length and basic sanity before being trusted
7. Formats a message per rep (name, score, trend arrow, coaching note) and sends it, looping until every rep in the batch has been covered

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create this workflow's schema

```bash
docker exec -it <postgres_container_name> psql -U n8n -c "CREATE SCHEMA IF NOT EXISTS sales_qa;"
```

### 2. Seed it

```bash
docker cp sales_qa_schema.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d <your_db> -f /tmp/sales_qa_schema.sql
```

This creates `sales_qa.calls`. Seed a few fake calls across at least two weeks (varying scores and dates) so Workflow B's trend comparison has something real to show.

### 3. Import the workflows

In n8n, import:

- `Sales Call QA - Call Scoring (A).json`
- `Sales Call QA - Coaching Digest (B).json`

(If you only see one exported file, both workflows were saved combined — import that single file and confirm both Workflow A and Workflow B appear as separate flows inside n8n after import.)

### 4. Point credentials at this schema

Both workflows' Postgres nodes need the shared Postgres credential, with queries fully-qualified against `sales_qa.calls` (rather than relying on a default schema).

### 5. Configure the call source

Whatever platform provides transcripts (Zoom, Google Meet, a dialer), make sure it labels which speaker is the rep and which is the customer before it hits the webhook — this workflow assumes that distinction already exists, since diarizing raw audio locally is out of scope here.

### 6. Run it

Send a test transcript to the webhook to run Workflow A end to end, then manually trigger Workflow B once at least one prior week and one current week of scored calls exist, to confirm the trend digest sends correctly.

---

## Schema

```sql
sales_qa.calls (
  id, call_id, rep_name, customer_name, company,
  call_date, duration_minutes, rep_transcript,
  status,              -- pending_scoring | scored | needs_review
  overall_score, scores,       -- scores is JSONB: one entry per rubric category
  coaching_needed, fail_reason, created_at
)
```
