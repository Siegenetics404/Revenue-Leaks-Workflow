# 07 — Contract Review and Red Flag Detection

Reads an uploaded contract clause by clause instead of judging the whole document at once, checks every clause against a fixed red-flag playbook and an AI model in parallel, verifies every AI-cited quote against the real clause text before trusting it, scores the contract's overall risk, and emails a full clause-by-clause report in minutes instead of waiting on a lawyer's first pass.

---

## What it does

**Contract Review Workflow**

1. A contract PDF is submitted through a form, along with the reviewer's role (`Client` or `Vendor`) and a contract name — role matters because the same clause can be safe for one side and dangerous for the other
2. Text is extracted from the PDF and split into individual clauses by their numbered headings, with oversized clauses further split on sentence boundaries so nothing exceeds the local model's context window
3. A rule-based scan runs first — a fixed playbook of red flag patterns (auto-renewal, uncapped liability, one-sided termination, net-60+ payment terms, IP assignment, non-compete, foreign jurisdiction, and more), filtered by the reviewer's role — and never depends on the AI's judgment
4. Clauses are then reviewed one at a time by a local LLM (via LM Studio) — a local model handles one request at a time, so clauses are looped rather than parallelized — with each clause judged only from the given role's side
5. Every AI finding passes through an automated guardrail — checks the cited quote actually appears in the real clause text (whitespace/punctuation normalized), that the risk level is a valid value, and that nothing looks like a placeholder or a refusal. A finding with a fabricated quote is rejected outright and never saved
6. Rejected clauses alert a human in plain language (not error codes) and the review continues to the next clause rather than stalling
7. AI and rule findings are merged per clause — an AI-only finding (no rule agrees) can never be rated High and is labeled as an unconfirmed AI observation, and a clause worded as mutually binding ("each party", "either party") that only the AI flagged is dropped rather than treated as a real finding
8. The merged findings are scored into an overall 0–100 risk score and Low/Medium/High rating
9. A local LLM drafts a plain-English executive summary and a "negotiate first" shortlist, built only from the verified findings — the "negotiate first" section is omitted entirely when there are no real High findings, so nothing gets padded to fill a list
10. A styled HTML report is generated, saved to Postgres, attached to an emailed summary, and — only if the contract scores High — an instant Telegram alert fires with the top red flags

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create the schema

```bash
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < schema.sql
```

This creates `contract_reviews` and `clause_findings` in the shared database (public schema, same as the earlier workflows). There's no seed data — this workflow only produces real rows once an actual contract is submitted through the form.

### 2. Import the workflow

In n8n, import:

- `Contract Review and Red Flag Detection.json`

### 3. Point credentials at the shared database

The Postgres nodes need the shared Postgres credential already used by the other workflows. The OpenAI-compatible nodes need the shared LM Studio credential. Gmail SMTP and the Telegram bot reuse the same credentials set up in workflow 1.

### 4. Prepare test contracts

The form only accepts text-based PDFs (not scans). Two test contracts are useful for a full check:

- A **dirty** contract with planted red flags across most clauses, to confirm the playbook and the AI both catch real problems
- A **clean**, balanced contract, to confirm the system doesn't invent findings on standard mutual language

### 5. Run it

Open the form (Test URL from the Form Trigger node), submit a contract PDF with a role and name, and wait — the AI loop is the slow part, since each clause waits on the local model. Confirm the dirty contract scores High and triggers the Telegram alert, and the clean contract scores Low with no alert and no padded "negotiate first" list.

---

## Schema

```sql
contract_reviews (
  id, contract_name, user_role,       -- 'Client' | 'Vendor'
  status,                              -- processing | complete
  clause_count, risk_score, risk_level,  -- Low | Medium | High
  summary, report_html, created_at
)

clause_findings (
  id, review_id, clause_no, heading, clause_text,
  source,                              -- 'ai' | 'rule'
  category, risk_level,                -- low | medium | high
  issue, quote, suggestion,
  valid, fail
)
```