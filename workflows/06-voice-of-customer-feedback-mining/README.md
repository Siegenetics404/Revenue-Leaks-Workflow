# 06 — Voice of Customer Feedback Mining

Reads every piece of incoming customer feedback, tags it by sentiment, severity, and theme using a local AI model, verifies every evidence quote against the real feedback text before trusting a tag, alerts on anything critical the moment it lands, and rolls classified feedback into a weekly per-theme trend digest instead of a pile nobody reads.

---

## What it does

**Workflow A — Feedback Classification**

1. New feedback rows (from reviews, support tickets, NPS comments, or social platforms) are picked up on a schedule from Postgres, where `status = 'new'`
2. Items are processed one at a time — a local model handles one request at a time, so batches are looped rather than parallelized
3. A local LLM (via LM Studio) classifies each item's sentiment, severity, and up to three themes from a fixed taxonomy, along with a verbatim quote backing the classification
4. Every classification passes through an automated guardrail — checks the quote actually appears in the real feedback text (apostrophe/quote-mark normalized), that themes fall within the allowed taxonomy, and that sentiment/severity are valid values. A quote the model invents or paraphrases is rejected outright
5. Items that fail the guardrail are flagged `flagged_invalid` and alert a human — never written to the record unverified
6. Items that pass are checked for severity: anything marked `critical` (churn threat, refund demand, legal/safety issue) triggers an instant alert, without waiting for the weekly digest
7. All validated items are marked `processed`, with sentiment, severity, themes, and the verified quote saved

**Workflow B — Weekly Trend Digest**

1. Runs on a weekly schedule
2. Pulls every item processed in the last 14 days, so both the current week and the prior week are available for comparison
3. Computes theme counts and trend deltas week-over-week, a sentiment split, the top verbatim quotes per leading theme, and the full list of critical items with their real customer names and quotes
4. A local LLM drafts a short executive summary, required to state the exact total feedback count, the biggest trending theme, and — only if any critical items exist — their real names, never a placeholder
5. The summary passes through a guardrail checking the total is actually referenced and that every real critical-item name appears in the text, not an invented one
6. Formats a styled HTML digest (stat cards, a theme trend table with up/down indicators, sentiment chips, a critical-issues callout, and grouped verbatim quotes) and emails it out

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create this workflow's schema

```bash
docker exec -it <postgres_container_name> psql -U n8n -c "CREATE SCHEMA IF NOT EXISTS voc_feedback;"
```

### 2. Seed it

```bash
docker cp schema_and_seed.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d <your_db> -f /tmp/schema_and_seed.sql
```

This creates `voc_feedback.feedback_items` and seeds 25 fake feedback rows across reviews, support tickets, and NPS comments, spanning the last two weeks with a realistic mix of sentiment and severity (including two deliberately critical rows), so Workflow B's trend comparison has something real to show.

### 3. Import the workflows

In n8n, import:

- `Voice of Customer - Feedback Classification (A).json`
- `Voice of Customer - Weekly Trend Digest (B).json`

(If you only see one exported file, both workflows were saved combined — import that single file and confirm both Workflow A and Workflow B appear as separate flows inside n8n after import.)

### 4. Point credentials at this schema

Both workflows' Postgres nodes need the shared Postgres credential, with queries fully-qualified against `voc_feedback.feedback_items` (rather than relying on a default schema).

### 5. Configure the feedback source

Whatever platform feedback comes from (Facebook, Google Reviews, Trustpilot, Zendesk, a survey tool), a small intake workflow — Webhook or API poll → Postgres insert — should feed rows into this same table with the right `source` value. This build ships with seeded data standing in for that intake layer, since the classification and digest logic is the reusable core regardless of how many platforms feed it.

### 6. Run it

Execute Workflow A to classify the seeded batch, confirm critical items (Carlos Mendes, Omar Haddad in the seed data) trigger the real-time alert, then manually trigger Workflow B once enough processed items exist across two weeks to confirm the trend digest sends correctly.

---

## Schema

```sql
voc_feedback.feedback_items (
  id, source, customer_name, customer_email, rating,
  raw_text, submitted_at,
  status,              -- new | processed | flagged_invalid
  sentiment, severity, themes,   -- themes is JSONB: up to 3 tags from the taxonomy
  key_quote, processed_at
)
```
