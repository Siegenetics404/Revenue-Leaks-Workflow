-- Sales Call QA and Coaching Analysis — schema
-- Workflow 05 of 10

CREATE SCHEMA IF NOT EXISTS sales_qa;

CREATE TABLE IF NOT EXISTS sales_qa.calls (
  id SERIAL PRIMARY KEY,
  call_id TEXT UNIQUE NOT NULL,
  rep_name TEXT NOT NULL,
  customer_name TEXT,
  company TEXT,
  call_date DATE NOT NULL,
  duration_minutes NUMERIC,
  rep_transcript TEXT,
  status TEXT NOT NULL DEFAULT 'pending_scoring',
  overall_score NUMERIC,
  scores JSONB,
  coaching_needed BOOLEAN DEFAULT false,
  fail_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- status values: pending_scoring -> scored | needs_review

CREATE INDEX IF NOT EXISTS idx_sales_qa_calls_rep_date
  ON sales_qa.calls (rep_name, call_date);

CREATE INDEX IF NOT EXISTS idx_sales_qa_calls_status
  ON sales_qa.calls (status);
