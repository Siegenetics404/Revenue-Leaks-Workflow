-- 09 — SOP and Documents Generator
-- Schema: sop_documents, sop_versions, sop_reviews

CREATE TABLE IF NOT EXISTS sop_documents (
  id                   SERIAL PRIMARY KEY,
  title                TEXT NOT NULL UNIQUE,
  category             TEXT,
  status               TEXT DEFAULT 'draft',   -- draft | in_review | approved | archived
  current_version_id   INT,
  requested_by         TEXT,
  created_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sop_versions (
  id                   SERIAL PRIMARY KEY,
  document_id          INT REFERENCES sop_documents(id),
  version_number       INT,
  raw_input            TEXT,
  structured_json      JSONB,
  rendered_markdown    TEXT,
  completeness_score   INT,
  missing_fields       TEXT,
  created_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sop_reviews (
  id                   SERIAL PRIMARY KEY,
  version_id           INT REFERENCES sop_versions(id),
  reviewer             TEXT,
  decision             TEXT,   -- approved | rejected | revision_requested
  feedback             TEXT,
  created_at           TIMESTAMP DEFAULT NOW()
);

-- Helpful indexes for the lookups the workflow does most often
CREATE INDEX IF NOT EXISTS idx_sop_documents_status ON sop_documents(status);
CREATE INDEX IF NOT EXISTS idx_sop_versions_document_id ON sop_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_sop_reviews_version_id ON sop_reviews(version_id);