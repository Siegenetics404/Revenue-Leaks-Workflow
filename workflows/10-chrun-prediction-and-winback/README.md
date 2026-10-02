-- 10 — Churn Prediction and Winback
-- Safe to re-run: every statement is IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS customers (
  id SERIAL PRIMARY KEY,
  first_name TEXT,
  company TEXT,
  email TEXT UNIQUE,
  plan TEXT,
  mrr NUMERIC,
  signup_date DATE,
  renewal_date DATE,
  last_login_at TIMESTAMP,
  status TEXT DEFAULT 'active',        -- active | at_risk | churned | won_back | lost | unsubscribed
  risk_score INT,
  risk_tier TEXT,                      -- low | medium | high
  risk_signals JSONB,
  last_scored_at TIMESTAMP,
  last_intervention_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancel_reason_raw TEXT,
  cancel_reason TEXT,                  -- PRICE | MISSING_FEATURE | COMPETITOR | NOT_USING | SUPPORT_BAD | BUSINESS_CLOSED | UNKNOWN
  winback_touch INT DEFAULT 0,
  next_winback_at TIMESTAMP,
  won_back_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS usage_weekly (
  customer_id INT REFERENCES customers(id),
  week_start DATE,
  logins INT,
  key_actions INT,
  PRIMARY KEY (customer_id, week_start)
);

CREATE TABLE IF NOT EXISTS support_tickets (
  id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(id),
  created_at TIMESTAMP,
  sentiment TEXT,                      -- positive | neutral | negative
  subject TEXT
);

-- named churn_invoices because "invoices" belongs to the accounts receivable workflow
CREATE TABLE IF NOT EXISTS churn_invoices (
  id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(id),
  due_date DATE,
  status TEXT,                         -- paid | failed
  amount NUMERIC
);

CREATE TABLE IF NOT EXISTS score_history (
  customer_id INT,
  scored_at TIMESTAMP DEFAULT NOW(),
  risk_score INT,
  risk_tier TEXT
);

CREATE TABLE IF NOT EXISTS interventions (
  id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(id),
  kind TEXT,                           -- checkin_email | human_briefing | winback_email
  touch_no INT,
  subject TEXT,
  body TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  outcome TEXT
);

CREATE TABLE IF NOT EXISTS offers (
  reason TEXT PRIMARY KEY,
  code TEXT,
  description TEXT,
  discount_pct INT
);

CREATE TABLE IF NOT EXISTS product_updates (
  id SERIAL PRIMARY KEY,
  released_at DATE,
  title TEXT,
  summary TEXT
);

-- shared with the earlier workflows; skipped if it already exists
CREATE TABLE IF NOT EXISTS suppression_list (
  email TEXT,
  reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_next_winback ON customers(next_winback_at);
CREATE INDEX IF NOT EXISTS idx_score_history_customer ON score_history(customer_id, scored_at);
CREATE INDEX IF NOT EXISTS idx_interventions_customer ON interventions(customer_id);