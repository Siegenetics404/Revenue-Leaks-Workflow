CREATE TABLE calls (
  id SERIAL PRIMARY KEY,
  call_id TEXT UNIQUE,
  caller_number TEXT,
  started_at TIMESTAMPTZ,
  duration_sec INT,
  ended_reason TEXT,
  transcript TEXT,
  recording_url TEXT,
  caller_name TEXT,
  reason TEXT,
  urgency TEXT,
  wants_appointment BOOLEAN,
  callback_needed BOOLEAN,
  summary TEXT,
  status TEXT DEFAULT 'new',
  followup_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE appointments (
  id SERIAL PRIMARY KEY,
  slot_start TIMESTAMP UNIQUE NOT NULL,
  caller_name TEXT,
  caller_number TEXT,
  reason TEXT,
  call_id TEXT,
  status TEXT DEFAULT 'booked',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE suppression (number TEXT PRIMARY KEY);
