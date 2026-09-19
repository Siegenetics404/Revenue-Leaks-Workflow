# Revenue Leak Automations

A series of 10 AI-powered automation workflows, each built to plug a specific revenue leak most businesses don't realize they have — cold leads, missed calls, slow RFP responses, unpaid invoices, and more.

Every workflow in this repo is built on the same constraint: **zero cost**. No paid APIs, no subscriptions, no vendor lock-in. Orchestration runs on self-hosted n8n, AI runs on a local model through LM Studio, and everything else uses free tooling wherever possible.

This repo hosts one shared n8n + Postgres environment. Each workflow lives in its own database and its own set of exported workflow JSON files, but all of them run inside the same Docker setup.

---

## The series

| # | Workflow | Status |
|---|---|---|
| 01 | [Dead Lead Reactivation](./workflows/01-dead-lead-reactivation) | ✅ Complete |
| 02 | AI Voice Receptionist for Missed Calls | 🔜 Planned |
| 03 | RFP / Tender Response Automation | 🔜 Planned |
| 04 | Accounts Receivable & Payment Chasing | 🔜 Planned |
| 05 | Sales Call QA & Coaching Analysis | 🔜 Planned |
| 06 | Voice-of-Customer Feedback Mining | 🔜 Planned |
| 07 | Contract Review & Red Flag Detection | 🔜 Planned |
| 08 | E-commerce Product Listing Factory | 🔜 Planned |
| 09 | SOP & Document Generator | 🔜 Planned |
| 10 | Churn Prediction & Winback | 🔜 Planned |

---

## Shared stack

| Layer | Tool | Cost |
|---|---|---|
| Orchestration | [n8n](https://n8n.io) (self-hosted, Docker) | Free |
| AI | [LM Studio](https://lmstudio.ai) (local model server) | Free |
| Database | PostgreSQL (Docker, one database per workflow) | Free |
| Sending | Gmail SMTP | Free |
| Reply capture | Gmail IMAP | Free |
| Alerts | Telegram Bot API | Free |

---

## Prerequisites

- Docker and Docker Compose installed
- [LM Studio](https://lmstudio.ai) installed, with a model downloaded (tested with Qwen2.5-7B-Instruct)
- A Gmail account with 2-Step Verification enabled, and an [App Password](https://myaccount.google.com/apppasswords) generated
- A Telegram bot token, created via [@BotFather](https://t.me/BotFather)

---

## Environment setup (do this once)

### 1. Clone and configure

```bash
git clone <this-repo-url>
cd revenue-leak-automations
cp .env.example .env
```

Edit `.env` with your own values:

```
POSTGRES_USER=n8n
POSTGRES_PASSWORD=<choose-your-own-password>
```

Note there's no single `POSTGRES_DB` here — each workflow gets its own database, created individually per workflow (see each workflow's own README).

### 2. Start the containers

```bash
docker compose up -d
docker ps
```

Confirm the `n8n` and `postgres` containers are both running. n8n is available at `http://localhost:5678`.

### 3. Set up LM Studio

Open LM Studio, load a model, go to the **Developer** tab, start the local server, and enable **Serve on Local Network**. Note the port (default `1234`).

n8n reaches your host machine at `http://host.docker.internal:1234/v1` — already configured in `docker-compose.yml` via `extra_hosts`.

Create one shared n8n credential for this: **OpenAI** type, API key `lm-studio` (any non-empty string, ignored by LM Studio), base URL `http://host.docker.internal:1234/v1`. Every workflow's AI nodes reuse this same credential.

### 4. Set up shared credentials

These are created once in n8n and reused across every workflow in the series:

- **Postgres** — host `postgres`, port `5432`, user/password from `.env`, database set per-workflow (see each workflow's own setup)
- **LM Studio (as OpenAI credential)** — see above
- **SMTP** — host `smtp.gmail.com`, port `465`, SSL on, your Gmail address, your App Password
- **IMAP** — host `imap.gmail.com`, port `993`, SSL on, your Gmail address, your App Password
- **Telegram** — your bot token from BotFather

---

## Adding a new workflow to this repo

1. Create its own database:
   ```bash
   docker exec -it <postgres_container_name> psql -U n8n -c "CREATE DATABASE <workflow_db_name>;"
   ```
2. Add a new folder under `workflows/`, e.g. `workflows/02-missed-call-receptionist/`
3. Put that workflow's seed SQL, exported n8n JSON files, and its own short README (covering anything specific to that workflow — its schema, its unique setup steps) inside that folder
4. Import its JSON into n8n and point its Postgres node at the new database, reusing the shared credentials above wherever they apply

---

## Repo structure

```
revenue-leak-automations/
├── docker-compose.yml
├── .env.example
├── README.md                          
└── workflows/
    └── 01-dead-lead-reactivation/
        ├── README.md                 
        ├── reactivation_seed.sql
        ├── 01 Dead Lead Reactivation.json
        └── 01 Reply Handling.json
```

---

## General notes

**Deliverability.** Workflows that send email use a personal Gmail account via SMTP, fine for testing and low-volume use, but not production-grade sending infrastructure. A real client deployment needs a verified sending domain with SPF/DKIM/DMARC, and ideally a dedicated sending service.

**Concurrency.** None of these workflows currently include execution locking. Triggering a workflow twice in quick succession runs two full executions in parallel — database writes are safe (Postgres handles concurrent atomic updates correctly), but duplicate alerts can occur. Worth adding a lock table before putting any of these on a live schedule.