-- RFP and Tender Response Automation: schema
-- Requires the pgvector image (pgvector/pgvector:pg16) in docker-compose.yml

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE library_chunks (
  id SERIAL PRIMARY KEY,
  source TEXT,
  section TEXT,
  content TEXT NOT NULL,
  content_hash TEXT UNIQUE,
  approved BOOLEAN DEFAULT TRUE,
  embedding vector(768),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX ON library_chunks USING hnsw (embedding vector_cosine_ops);

CREATE TABLE rfps (
  id SERIAL PRIMARY KEY,
  title TEXT,
  issuer TEXT,
  deadline TIMESTAMP,
  bid_score INT,
  bid_reasons TEXT,
  status TEXT DEFAULT 'received',
  raw_text TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rfp_questions (
  id SERIAL PRIMARY KEY,
  rfp_id INT REFERENCES rfps(id),
  q_number TEXT,
  question TEXT,
  mandatory BOOLEAN DEFAULT FALSE,
  category TEXT,
  draft_answer TEXT,
  sources TEXT,
  top_similarity NUMERIC,
  status TEXT DEFAULT 'pending',
  fail TEXT
);
