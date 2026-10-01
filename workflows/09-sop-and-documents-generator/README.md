# 09 — SOP and Documents Generator

Turns raw, messy process notes into a structured, version-controlled SOP without letting a half-documented process ship as official. A model extracts the steps, roles, tools, and exceptions into structured data, a completeness guardrail blocks anything missing critical detail before it's ever sent for review, and nothing becomes the official document until a human approves it over Telegram — at which point it's generated as an actual file, not just a formatted message.

---

## What it does

**SOP Generator - Generation (Workflow A)**

1. A submitter pastes raw process notes into Telegram, with the first line formatted as `TITLE: <name>` so the document title and body are parsed deterministically
2. The workflow checks whether a document with that title already exists — a new title creates a document, a resubmitted title becomes the next version of the same one
3. A model (via LM Studio) extracts the notes into structured JSON: purpose, roles, tools, prerequisites, an ordered list of steps (actor, action, tool), exceptions, and warnings
4. Every draft passes through a completeness guardrail that checks seven things before it's trusted: a real purpose statement, at least one role, at least one tool, at least three steps, every step naming an actor, steps numbered without gaps, and an exceptions field present (even if empty)
5. A draft that fails the guardrail is never saved — the submitter gets a Telegram message listing exactly what's missing, and nothing reaches review
6. A draft that passes is rendered into a consistent house-style Markdown document, saved as a new version, and sent to the reviewer with an APPROVE / REJECT / REVISE prompt

**SOP Generator - Review and Revision (Workflow B)**

7. The same Telegram trigger splits reviewer replies from new submissions by checking whether the message starts with `TITLE:`
8. A reply is parsed deterministically first (`APPROVE`, `REJECT`, `REVISE: <feedback>`); anything that doesn't match is classified by a model instead, so a plain-English reply like "this looks fine, go ahead" still resolves to a decision
9. **Approve** logs the decision, marks the document `approved`, sends a confirmation, and generates the approved version as a real `.md` file sent to the reviewer as a document attachment
10. **Reject** logs the decision and archives the document
11. **Revise** logs the reviewer's feedback, regenerates the SOP by feeding the previous structured version, the original notes, and the feedback back through the same model, runs the result through the same completeness guardrail, and — if it passes — saves it as the next version and sends it back for another round

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create the schema

```bash
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < schema.sql
```

This creates `sop_documents`, `sop_versions`, and `sop_reviews` in the shared database (public schema, same as the earlier workflows).

### 2. Import the workflows

In n8n, import both:

- `SOP Generator - Generation.json`
- `SOP Generator - Review and Revision.json`

### 3. Point credentials at the shared services

The Postgres nodes need the shared Postgres credential already used by the other workflows. The AI nodes need the shared LM Studio credential. The Telegram nodes reuse the same bot credential set up in workflow 1 — note that Telegram allows only one active trigger per bot, so this bot can't be listening in another workflow at the same time.

### 4. Seed a test submission

Send a message to the bot with a real process, formatted as:

```
TITLE: Customer Refund Process
When a customer asks for a refund, support checks the order in Shopify first...
```

One deliberately thin submission (two vague steps, no tools named) is worth sending too, to confirm the guardrail actually blocks it instead of letting a confident-sounding draft through.

### 5. Expose n8n to Telegram

The Generation and Review workflows share one Telegram Trigger, so only one webhook needs registering. A Cloudflare quick tunnel (`cloudflared tunnel --url http://localhost:5678`) works for local testing, set as `WEBHOOK_URL` in `.env`. A quick tunnel's URL changes on every restart, so a named tunnel is worth setting up before this needs to stay stable across sessions.

### 6. Run it

Submit a complete SOP and confirm it renders cleanly and arrives with the APPROVE/REJECT/REVISE prompt. Reply `REVISE: <feedback>` and confirm a new version comes back reflecting it. Reply `APPROVE` and confirm both the text confirmation and an actual `.md` file attachment arrive. Then submit the thin test case and confirm it never reaches review, and reject a document to confirm it archives instead of ever coming back.

---

## Schema

```sql
sop_documents (
  id, title, category, status,     -- draft | in_review | approved | archived
  current_version_id, requested_by, created_at
)

sop_versions (
  id, document_id, version_number, raw_input,
  structured_json, rendered_markdown,
  completeness_score, missing_fields, created_at
)

sop_reviews (
  id, version_id, reviewer, decision, feedback, created_at
)
```
