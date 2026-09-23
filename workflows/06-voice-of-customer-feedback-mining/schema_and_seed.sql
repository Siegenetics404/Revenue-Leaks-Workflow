-- Voice of Customer Feedback Mining
-- Workflow 6 of 10 — n8n automation portfolio
--
-- Stores raw customer feedback (reviews, support tickets, NPS comments,
-- social mentions) and the structured classification produced by
-- Workflow A (Voice of Customer — Feedback Classification).
--
-- Workflow B (Voice of Customer — Weekly Trend Digest) reads processed
-- rows from this table to build the weekly report.

CREATE TABLE feedback_items (
  id              SERIAL PRIMARY KEY,

  -- Where the feedback came from: 'review', 'support_ticket',
  -- 'nps_comment', 'facebook', 'google_reviews', 'trustpilot', etc.
  -- In production, each platform gets its own small intake workflow
  -- (Webhook or API poll) that inserts into this same table.
  source          TEXT,

  customer_name   TEXT,
  customer_email  TEXT,
  rating          NUMERIC,           -- nullable, e.g. NPS 0-10 or stars

  raw_text        TEXT NOT NULL,
  submitted_at    TIMESTAMP DEFAULT NOW(),

  -- new -> processed (guardrail passed) / flagged_invalid (guardrail failed)
  status          TEXT DEFAULT 'new',

  -- Set by Workflow A after AI classification + guardrail verification
  sentiment       TEXT,              -- positive / neutral / negative / mixed
  severity        TEXT,              -- critical / high / medium / low
  themes          JSONB,             -- e.g. ["pricing", "onboarding"]
  key_quote       TEXT,              -- verbatim quote backing the tags,
                                      -- checked against raw_text before save

  processed_at    TIMESTAMP
);

-- Allowed values, enforced in application code (n8n guardrail node),
-- not as a DB constraint, so the taxonomy can evolve per client:
--
-- themes:    pricing, onboarding, reliability_bugs, feature_request,
--            customer_support, performance_speed, ui_ux, documentation,
--            integration, billing, other
-- severity:  critical, high, medium, low
-- sentiment: positive, neutral, negative, mixed

-- Helpful indexes for the classification and digest workflows
CREATE INDEX idx_feedback_status ON feedback_items (status);
CREATE INDEX idx_feedback_submitted_at ON feedback_items (submitted_at);
CREATE INDEX idx_feedback_severity ON feedback_items (severity);


-- Seed data for local testing — 25 fake feedback rows across
-- reviews, support tickets, and NPS comments, with a realistic mix
-- of sentiment and severity (including 2 deliberately critical rows
-- to test the real-time alert branch).

INSERT INTO feedback_items (source, customer_name, customer_email, rating, raw_text, submitted_at) VALUES
('review', 'Maria Santos', 'maria.s@example.com', 2, 'The app crashes every time I try to export a report. This has been happening for two weeks and support hasnt responded to my last three emails. If this isnt fixed by end of month Im cancelling and moving to a competitor.', NOW() - INTERVAL '1 day'),
('nps_comment', 'James Cooper', 'jcooper@example.com', 9, 'Really love how fast the dashboard loads now compared to last year. Onboarding was smooth too, my whole team was up and running in a day.', NOW() - INTERVAL '2 days'),
('support_ticket', 'Anthony Reyes', 'a.reyes@example.com', NULL, 'Is there a way to bulk-import contacts from a CSV? I have about 3000 rows and doing it one by one is not realistic for us.', NOW() - INTERVAL '2 days'),
('review', 'Linda Park', 'lpark@example.com', 4, 'Good product overall but the pricing tiers are confusing. Wasnt clear that the automations feature needed the higher plan until I hit the limit mid-project.', NOW() - INTERVAL '3 days'),
('support_ticket', 'Derek Wu', 'dwu@example.com', NULL, 'Getting a 500 error whenever I try to connect my Google account. Tried three times today.', NOW() - INTERVAL '3 days'),
('nps_comment', 'Priya Nair', 'pnair@example.com', 3, 'The interface feels cluttered, hard to find basic settings. Support was helpful when I asked though.', NOW() - INTERVAL '4 days'),
('review', 'Carlos Mendes', 'cmendes@example.com', 1, 'Charged me for a plan I never upgraded to. This is basically theft. I want a refund immediately or I am disputing the charge with my bank and posting about this everywhere.', NOW() - INTERVAL '4 days'),
('review', 'Sofia Alvarez', 'salvarez@example.com', 5, 'Best tool weve used for this. The reporting feature alone saved my team hours every week.', NOW() - INTERVAL '5 days'),
('support_ticket', 'Nathan Brooks', 'nbrooks@example.com', NULL, 'Would be great if you could add dark mode. Not urgent but a lot of us on the team would use it.', NOW() - INTERVAL '5 days'),
('nps_comment', 'Emily Chen', 'echen@example.com', 6, 'Its fine, does what it needs to. Documentation could be better though, spent a while figuring out the API auth flow.', NOW() - INTERVAL '6 days'),
('review', 'Tom Fischer', 'tfischer@example.com', 2, 'Integration with Slack keeps disconnecting randomly, have to reauthorize every few days. Really disruptive to our workflow.', NOW() - INTERVAL '6 days'),
('support_ticket', 'Rachel Kim', 'rkim@example.com', NULL, 'Loving the new update. Just wanted to flag that the export button is a bit hard to find now, took me a minute to locate it.', NOW() - INTERVAL '7 days'),
('review', 'Omar Haddad', 'ohaddad@example.com', 1, 'Cancelled my subscription last month and youre still charging my card. Fix this now or Im contacting my lawyer.', NOW() - INTERVAL '7 days'),
('nps_comment', 'Grace Liu', 'gliu@example.com', 8, 'Solid product. Only complaint is customer support response time, took two days to hear back on a minor question.', NOW() - INTERVAL '8 days'),
('review', 'Ben Foster', 'bfoster@example.com', 3, 'Onboarding docs are outdated, referenced buttons that dont exist anymore in the current UI.', NOW() - INTERVAL '8 days'),
('support_ticket', 'Hannah Scott', 'hscott@example.com', NULL, 'Can you add a way to schedule recurring reports? Would save me from manually running this every Monday.', NOW() - INTERVAL '9 days'),
('review', 'Marcus Webb', 'mwebb@example.com', 5, 'Switched from a competitor and honestly should have done it sooner. Setup was painless.', NOW() - INTERVAL '9 days'),
('review', 'Diana Ruiz', 'druiz@example.com', 2, 'App is painfully slow when I have more than a few hundred rows loaded. Basically unusable for our size of account.', NOW() - INTERVAL '10 days'),
('support_ticket', 'Kevin Patel', 'kpatel@example.com', NULL, 'Billing page shows the wrong currency for our account, everything is listed in USD but we pay in GBP.', NOW() - INTERVAL '10 days'),
('nps_comment', 'Olivia Turner', 'oturner@example.com', 9, 'Great experience so far, the team has been responsive and the product keeps improving.', NOW() - INTERVAL '11 days'),
('review', 'Sam Dawson', 'sdawson@example.com', 1, 'Lost two hours of work because the app crashed and didnt autosave. Extremely frustrating, considering switching tools.', NOW() - INTERVAL '11 days'),
('support_ticket', 'Chloe Bennett', 'cbennett@example.com', NULL, 'Any plans to support SSO for enterprise accounts? Its a blocker for us rolling this out company-wide.', NOW() - INTERVAL '12 days'),
('review', 'Isaac Reyes', 'ireyes@example.com', 4, 'Works well, wish there were more customization options for the dashboard widgets.', NOW() - INTERVAL '12 days'),
('nps_comment', 'Natalie Grant', 'ngrant@example.com', 2, 'Not happy. Third time this quarter Ive had a sync issue with our CRM and support keeps giving generic troubleshooting steps that dont fix it.', NOW() - INTERVAL '13 days'),
('review', 'Victor Lam', 'vlam@example.com', 5, 'Exactly what we needed. Clean UI, does the job without extra bloat.', NOW() - INTERVAL '13 days');