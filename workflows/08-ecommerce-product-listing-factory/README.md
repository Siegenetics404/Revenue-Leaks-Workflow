# 08 — E-commerce Product Listing Factory

Turns raw, messy product data into publish-ready Shopify listings without letting the AI ship anything on its own. A local model drafts the title, description, bullets, and SEO meta for each product (grouping color/size variants together so they share one honest listing instead of three contradicting ones), every draft is checked against six separate fabrication guardrails before it's saved, and nothing reaches the storefront until a human approves it over Telegram.

---

## What it does

**Listing Factory - Generation**

1. Pending products are pulled from the intake table and grouped by `variant_group`, so a tote bag in three colors is treated as one listing job, not three
2. A local LLM (via LM Studio) drafts a shared title, description, bullet points, SEO meta, and per-variant alt text from the raw product data — one group at a time, since a local model handles one request at a time
3. Every draft passes through a validation guardrail that checks for six distinct failure types before it's trusted: unsourced certification/eco claims, vague unsupported superlatives ("stylish", "premium"), a variant-specific detail (a color or size) leaking into the shared copy, a fabricated numeric spec not present in the source data, an internal placeholder note ("not specified") leaking into customer-facing text, and the SKU itself being mistaken for a brand name
4. A draft that fails any check is never saved — it's flagged with a plain-language reason sent to Telegram, and the product stays in the queue for the next run
5. A draft that passes is saved to the intake table and a Telegram message goes out with the title, description, and a plain "approve" / "reject" reply prompt

**Listing Factory - Approval**

6. A Telegram Trigger listens for your reply and parses it into an `approve <id>` or `reject <id> <reason>` command
7. On approve, the drafted listing is pulled and pushed to Shopify's Admin API as a **draft** product (never active/live), with the correct price carried over from the source data, and the returned Shopify product ID is saved back to the intake table
8. On reject, the product is reset to pending and your reason is folded into its `raw_notes`, so the next generation pass has your feedback as extra context

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running.

### 1. Create the schema

```bash
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < schema.sql
```

This creates `product_intake` in the shared database (public schema, same as the earlier workflows).

### 2. Import the workflows

In n8n, import both:

- `Listing Factory - Generation.json`
- `Listing Factory - Approval.json`

### 3. Point credentials at the shared services

The Postgres nodes need the shared Postgres credential already used by the other workflows. The AI node needs the shared LM Studio credential. The Telegram nodes reuse the same bot credential set up in workflow 1. The Shopify publish step needs its own Header Auth credential (`X-Shopify-Access-Token`) pointed at a Shopify Admin API access token — see the note below on token lifetime.

### 4. Seed test products

Insert 15–20 fake products into `product_intake`, including at least one `variant_group` with 2–3 rows sharing the same group name but different `variant_attrs` (e.g. `Color: Blue, Size: Large`). One product worth deliberately leaving with a missing field (no `material`, for example) is useful for confirming the guardrail doesn't let the model invent one.

### 5. Expose n8n to Telegram

The Approval workflow's Telegram Trigger needs a public webhook URL — a Cloudflare quick tunnel (`cloudflared tunnel --url http://localhost:5678`) works for local testing, set as `WEBHOOK_URL` in `.env`. A quick tunnel's URL changes on every restart, so a named tunnel is worth setting up before this needs to stay stable across sessions.

### 6. Run it

Trigger the Generation workflow manually and let it loop through the seeded batch. Confirm at least one product is deliberately provocative enough to trip a guardrail (an eco/certification word in `raw_notes`, or a variant group where the model might describe only one color) so you can see a flagged Telegram alert, not just clean passes. Then reply `approve <id>` to a drafted product and confirm it appears in Shopify admin as a draft (not live) with the correct price.

---

## Note on the Shopify access token

This workflow was built against the Shopify Dev Dashboard app flow (legacy custom apps stopped being creatable as of Jan 1, 2026). A Client Credentials Grant token from this flow expires every 24 hours — there's no permanent token option here, so the access token needs re-requesting periodically:

```bash
curl -X POST https://<store>.myshopify.com/admin/oauth/access_token \
  -H "Content-Type: application/json" \
  -d '{"client_id": "<client_id>", "client_secret": "<client_secret>", "grant_type": "client_credentials"}'
```

---

## Schema

```sql
product_intake (
  id, sku, raw_name, category, material, dimensions, price, raw_notes,
  variant_group, variant_attrs, image_url,
  status,                    -- pending | drafted | flagged | published
  generated_title, generated_description, generated_bullets,
  generated_seo_meta, generated_alt_text,
  shopify_product_id, created_at, reviewed_at
)
```
