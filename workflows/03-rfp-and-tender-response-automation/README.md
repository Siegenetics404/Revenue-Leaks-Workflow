# 03 — RFP and Tender Response Automation

Reads an RFP PDF, decides whether it is worth bidding on, and drafts an answer to every requirement using only your approved past responses. Every draft runs through an automated grounding check before it is accepted, anything the library cannot support is routed to a human instead of guessed, and the result comes back as a compliance matrix in Telegram. Runs fully local: n8n, LM Studio, and pgvector on Postgres.

---

## What it does

**Seed Library (run once per document)**

1. A form takes an approved company document (`.md` or `.txt`), such as an overview, security policy, case studies, pricing terms, or SLA
2. The text is split into chunks of about 180 words with one paragraph of overlap
3. Each chunk is embedded with `nomic-embed-text-v1.5` through LM Studio and stored in pgvector
4. Chunks are hashed, so uploading the same document twice does not create duplicates

**Workflow A — Intake and Bid/No-Bid**

1. An intake form takes the RFP title, the PDF, and an Override option
2. The PDF text is extracted and split into windows sized for a local model's context
3. A local LLM extracts facts only: issuer, deadline, contract value and currency, region, mandatory certifications, and required years of experience
4. Bid/no-bid is scored in code, not by the model, against a company profile (region, contract value range, certifications held, experience, days left to the deadline)
5. A low score stops the run with a Telegram no-bid alert that lists the reasons. Override = Yes forces the RFP through, and the score and reasons are still saved
6. A local LLM extracts every requirement (question number, text, mandatory flag, category). Malformed JSON is repaired, duplicates from overlapping windows are removed, and the rows are saved
7. The RFP is handed to Workflow B

**Workflow B — Answer Engine**

1. Pulls the pending questions for the RFP, mandatory ones first
2. Embeds each question and retrieves the four closest chunks from the approved library
3. Evidence gate: if nothing relevant comes back, the question is marked `needs_human` without calling the model
4. A local LLM drafts the answer from the retrieved sources only, and may return `INSUFFICIENT_EVIDENCE`
5. Every draft passes through a guardrail before it is accepted. It checks that:
   - the answer is plain prose, not JSON
   - the length is reasonable
   - every number exists in the sources
   - every capitalised name, place, or standard exists in the sources
   - every cited source id was actually retrieved
   - there are no placeholders or AI tells
6. Drafts that fail are kept, marked `needs_human`, and the reason is recorded, so a reviewer sees what the model tried and why it was flagged
7. When every question is processed, a compliance matrix CSV is built and sent to Telegram with a summary: drafted, partial, needs a human, and mandatory items still open. The RFP is marked `in_review`
8. A daily deadline watcher (9am) alerts when an `in_review` RFP is due within 3 days and still has open items

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Switch Postgres to the pgvector image

In `docker-compose.yml`, change the Postgres image:

```yaml
image: pgvector/pgvector:pg16
```

Existing data carries over because it is the same major version. If Postgres then warns about a collation version mismatch, run:

```bash
docker compose up -d postgres
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "REINDEX DATABASE $POSTGRES_DB;" -c "ALTER DATABASE $POSTGRES_DB REFRESH COLLATION VERSION;"'
```

### 2. Create the schema

```bash
docker cp rfp_schema.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d reactivation -f /tmp/rfp_schema.sql
```

This enables the `vector` extension and creates `library_chunks`, `rfps`, and `rfp_questions`.

### 3. Load the models in LM Studio

Load a chat model (Qwen2.5-7B-Instruct with an 8192 context works) and the embedding model `text-embedding-nomic-embed-text-v1.5`, with **Serve on Local Network** on. Confirm both are reachable from inside the n8n container:

```bash
docker compose exec n8n sh -c "wget -qO- --header='Content-Type: application/json' --post-data='{\"model\":\"text-embedding-nomic-embed-text-v1.5\",\"input\":\"search_document: hello\"}' http://host.docker.internal:1234/v1/embeddings | head -c 300"
```

### 4. Import the workflows

In n8n, import:

- `RFP Seed Library.json`
- `RFP Response Engine (B) Answers.json`
- `RFP Response Engine (A) Intake.json`

Import B before A. Workflow IDs change on import, so after importing, open A, select the `Run answer engine` node, and pick `RFP Response Engine (B) Answers` again.

### 5. Point credentials

All Postgres nodes need the shared Postgres credential, with **database** set to `reactivation`. The OpenAI nodes need the LM Studio credential (base URL `http://host.docker.internal:1234/v1`, any non-empty API key). The Telegram nodes need your bot credential and chat ID.

### 6. Seed the answer library

Open the test URL of the `Seed Form` trigger, and upload each file from `sample_library/` with a document name and section. Check the result:

```bash
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT id, source, section, vector_dims(embedding) AS dims FROM library_chunks ORDER BY id;"'
```

Every row should show `dims` = 768.

### 7. Run it

Open the test URL of the `RFP Intake` trigger and submit a PDF from `sample_rfps/`. Use `localhost` in the address, not the cloudflared tunnel. Publish both workflows to get permanent form URLs and to switch on the daily deadline check.

---

## Sample data and expected results

`sample_library/` holds five documents for a fictional company (Kestrel Digital Solutions), full of specific numbers so grounding can be tested. `sample_rfps/` holds two fake RFPs:

| RFP | What it tests | Expected result |
|---|---|---|
| Lakeview OBPLS | A good fit with 14 requirements, 3 of which the library cannot answer (SOC 2 report, disaster recovery RTO/RPO, USD 10M insurance) | Bid score 60. Roughly 11 drafted and 3 `needs_human`, with the three unanswerable items among the flagged. Mandatory items still open: 3.5 and 5.3 |
| Northgate Fleet Telematics | A tender to walk away from: wrong region, 4 days left, out-of-range budget, FedRAMP required | Score 0 and a no-bid alert. With Override = Yes it runs through, and every question ends up `needs_human` |

The model is not deterministic, so counts can shift by a question or two between runs.

---

## Customizing

- **Company profile:** the `PROFILE` block at the top of the `Score bid` node holds the regions, contract value range, held certifications, and thresholds used for bid/no-bid
- **Your company name:** the `IGNORE` set in the `Guardrail` node lists words exempt from the name check. Replace the Kestrel words with your own company name
- **Evidence threshold:** `THRESHOLD` in the `Build context` node (default 0.60)
- **Deadline window:** the `INTERVAL '3 days'` in the `Due soon` query

---

## Limits

- The guardrail catches invented numbers, names, places, standards, and bad citations. It cannot verify that a sentence is true, so a draft can still relabel a project or add filler. Every draft needs a human read before it goes into a bid
- With a small library, similarity scores do not separate answerable questions from unanswerable ones, so the evidence gate is only a floor. The model's own `INSUFFICIENT_EVIDENCE` answer and the guardrail do the real filtering
- A 7B local model sometimes returns malformed JSON or answers in the wrong shape. Both workflows repair or flag these, and a failed draft is never silently accepted
- Scanned PDFs need OCR first, and tables in PDFs flatten badly during extraction
- Speed: roughly 20 to 40 seconds per question on a local model, so a long RFP is an overnight job

---

## Schema

```sql
library_chunks (
  id, source, section, content, content_hash,
  approved,          -- only approved chunks are searched
  embedding,         -- vector(768), nomic-embed-text-v1.5
  created_at
)

rfps (
  id, title, issuer, deadline, bid_score, bid_reasons,
  status,            -- received | drafting | no_bid | in_review | ready
  raw_text, created_at
)

rfp_questions (
  id, rfp_id, q_number, question, mandatory, category,
  draft_answer, sources, top_similarity,
  status,            -- pending | drafted | partial | needs_human | approved
  fail               -- why the guardrail flagged the draft
)
```