-- Workflow 7: Contract Review and Red Flag Detection
-- Tables for storing clause-level AI + rule-based contract reviews

CREATE TABLE IF NOT EXISTS contract_reviews (
  id SERIAL PRIMARY KEY,
  contract_name TEXT,
  user_role TEXT,              -- 'Client' or 'Vendor'
  status TEXT DEFAULT 'processing',   -- processing / complete
  clause_count INT,
  risk_score INT,
  risk_level TEXT,              -- Low / Medium / High
  summary TEXT,
  report_html TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clause_findings (
  id SERIAL PRIMARY KEY,
  review_id INT REFERENCES contract_reviews(id),
  clause_no INT,
  heading TEXT,
  clause_text TEXT,
  source TEXT,                  -- 'ai' or 'rule'
  category TEXT,
  risk_level TEXT,              -- low / medium / high
  issue TEXT,
  quote TEXT,
  suggestion TEXT,
  valid BOOLEAN,
  fail TEXT
);

-- Helpful index for pulling all findings on a review, ordered for the report
CREATE INDEX IF NOT EXISTS idx_clause_findings_review
  ON clause_findings (review_id, clause_no);