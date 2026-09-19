-- ============================================================
-- Dead Lead Reactivation - demo database
-- Postgres 14+
-- ============================================================

DROP TABLE IF EXISTS email_log;
DROP TABLE IF EXISTS suppression_list;
DROP TABLE IF EXISTS leads;

CREATE TABLE leads (
    id                  SERIAL PRIMARY KEY,
    first_name          TEXT NOT NULL,
    last_name           TEXT,
    company             TEXT NOT NULL,
    email               TEXT UNIQUE NOT NULL,
    industry            TEXT,
    last_purchase_date  DATE,
    last_contact_date   DATE,
    deal_value          NUMERIC(10,2) DEFAULT 0,
    lost_reason         TEXT,
    status              TEXT NOT NULL DEFAULT 'dead',
    touch_count         INT  NOT NULL DEFAULT 0,
    next_touch_at       TIMESTAMP,
    last_sent_subject   TEXT,
    last_sent_body      TEXT,
    replied_at          TIMESTAMP,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW(),
    CONSTRAINT status_values CHECK (status IN
        ('dead','in_reactivation','replied','exhausted','unsubscribed'))
);

CREATE INDEX idx_leads_due ON leads (status, touch_count, next_touch_at);

CREATE TABLE suppression_list (
    email       TEXT PRIMARY KEY,
    reason      TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE email_log (
    id              SERIAL PRIMARY KEY,
    lead_id         INT REFERENCES leads(id) ON DELETE CASCADE,
    touch_number    INT,
    subject         TEXT,
    body            TEXT,
    validation_pass BOOLEAN,
    validation_fail TEXT,
    sent_at         TIMESTAMP DEFAULT NOW()
);

INSERT INTO leads
(first_name, last_name, company, email, industry, last_purchase_date,
 last_contact_date, deal_value, lost_reason, status, touch_count,
 next_touch_at, replied_at)
VALUES
('Marcus','Whitfield','Whitfield Plumbing Ltd','franco.cj03+lead01@gmail.com',
 'Home Services','2024-02-11','2024-03-04', 8400.00,
 'Went with a cheaper local competitor','dead',0,NULL,NULL),
('Priya','Raghavan','Nordwell Interiors','franco.cj03+lead02@gmail.com',
 'Interior Design','2023-11-20','2024-01-15', 12500.00,
 'Budget was cut mid-project, never resumed','dead',0,NULL,NULL),
('Tom','Alderton','Alderton Heating Services','franco.cj03+lead03@gmail.com',
 'HVAC',NULL,'2024-05-22', 3200.00,
 'Ghosted after the proposal, no reason given','dead',0,NULL,NULL),
('Sofia','Marchetti','Bellacasa Kitchens','franco.cj03+lead04@gmail.com',
 'Kitchen Fitting','2023-08-30','2023-09-12', 21000.00,
 'Timeline was too long, needed it before Christmas','dead',0,NULL,NULL),
('Dean','Okafor','Okafor Electrical','franco.cj03+lead05@gmail.com',
 'Electrical',NULL,'2025-01-08', 1800.00,
 'Said they would think about it and never came back','dead',0,NULL,NULL),
('Helen','Brightwater','Brightwater Landscaping','franco.cj03+lead06@gmail.com',
 'Landscaping','2024-06-01','2025-08-14', 6700.00,
 'Decided to handle it in house','in_reactivation',1,
 NOW() - INTERVAL '2 days', NULL),
('Raj','Patel','Patel Property Group','franco.cj03+lead07@gmail.com',
 'Property',NULL,'2025-07-30', 34000.00,
 'Project was shelved when their funding fell through','in_reactivation',1,
 NOW() - INTERVAL '1 day', NULL),
('Fiona','Mackenzie','Mackenzie Joinery','franco.cj03+lead08@gmail.com',
 'Carpentry','2023-04-19','2025-09-02', 4900.00,
 'Never responded to the revised quote','in_reactivation',2,
 NOW() - INTERVAL '3 days', NULL),
('Callum','Reed','Reed Roofing Co','franco.cj03+lead09@gmail.com',
 'Roofing',NULL,'2025-09-05', 15200.00,
 'Chose a contractor their insurer recommended','in_reactivation',2,
 NOW() - INTERVAL '4 hours', NULL),
('Nadia','Fischer','Fischer Glazing','franco.cj03+lead10@gmail.com',
 'Glazing',NULL,'2025-09-10', 2400.00,
 'Not interested in the upsell','in_reactivation',3,
 NOW() - INTERVAL '1 day', NULL),
('Owen','Tremaine','Tremaine Builders','franco.cj03+lead11@gmail.com',
 'Construction','2024-09-09','2025-09-01', 18900.00,
 'Paused after phase one','replied',1,
 NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days'),
('Grace','Lindqvist','Lindqvist Flooring','franco.cj03+lead12@gmail.com',
 'Flooring',NULL,'2025-06-18', 5300.00,
 'Asked to be removed from all lists','unsubscribed',1,
 NULL, NULL),
('Bilal','Hassan','Hassan Tiling','franco.cj03+lead13@gmail.com',
 'Tiling',NULL,'2025-04-02', 2100.00,
 'No budget this year','exhausted',3,NULL,NULL),
('Iris','Delacroix','Delacroix Design Studio','franco.cj03+lead14@gmail.com',
 'Design',NULL,'2025-09-15', 9600.00,
 'Wanted to revisit in the new financial year','in_reactivation',1,
 NOW() + INTERVAL '3 days', NULL),
('Viktor','Ivanov','Ivanov Commercial Fitouts','franco.cj03+lead15@gmail.com',
 'Commercial',NULL,'2024-10-11', 87000.00,
 'Went quiet after the site survey','dead',0,NULL,NULL),
('Amara','Nwosu','Nwosu Cleaning Services','franco.cj03+lead16@gmail.com',
 'Cleaning','2024-01-05','2024-02-20', 900.00,
 'Too expensive for a monthly retainer','dead',0,NULL,NULL),
('Lars','Bergstrom','Bergstrom Windows','franco.cj03+lead17@gmail.com',
 'Windows',NULL,'2023-12-01', 11400.00,
 'Preferred a supplier with a longer warranty','dead',0,NULL,NULL),
('Chloe','Ashworth','Ashworth Bathrooms','franco.cj03+lead18@gmail.com',
 'Bathrooms','2024-07-22','2024-08-30', 7200.00,
 'Renovation postponed indefinitely','dead',0,NULL,NULL),
('Samuel','Kirui','Kirui Groundworks','franco.cj03+lead19@gmail.com',
 'Groundworks',NULL,'2025-02-14', 26500.00,
 'Lost the tender to a larger firm','dead',0,NULL,NULL),
('Yuki','Tanaka','Tanaka Architectural','franco.cj03+lead20@gmail.com',
 'Architecture',NULL,'2025-03-28', 41000.00,
 'Client changed direction after concept stage','dead',0,NULL,NULL),
('Erik','Solheim','Solheim Marine','franco.cj03+lead21@gmail.com',
 'Marine',NULL,'2025-05-09', 13800.00,
 NULL,'dead',0,NULL,NULL),
('Maeve','O''Sullivan','O''Sullivan & Daughters','franco.cj03+lead22@gmail.com',
 'Construction','2024-03-17','2024-04-25', 5600.00,
 'Preferred to work with a firm they had used before','dead',0,NULL,NULL),
('Hugo','Vasquez','Vasquez Restoration','franco.cj03+lead23@gmail.com',
 'Restoration','2021-06-14','2021-07-02', 19500.00,
 'Project completed, no follow up work booked','dead',0,NULL,NULL),
('Nina','Kovacs','Kovacs Signage','franco.cj03+lead24@gmail.com',
 'Signage',NULL,'2025-08-01', 0.00,
 'Enquiry only, never quoted','dead',0,NULL,NULL);

INSERT INTO suppression_list (email, reason) VALUES
('franco.cj03+lead12@gmail.com','Requested removal by reply, 2025-06-18'),
('franco.cj03+blocked01@gmail.com','Bounced 3 times'),
('franco.cj03+blocked02@gmail.com','Marked as spam');

SELECT l.id, l.first_name, l.company, l.touch_count, l.deal_value,
       (CURRENT_DATE - l.last_contact_date) AS days_cold
FROM leads l
LEFT JOIN suppression_list s ON s.email = l.email
WHERE l.status IN ('dead','in_reactivation')
  AND l.touch_count < 3
  AND (l.next_touch_at IS NULL OR l.next_touch_at <= NOW())
  AND l.replied_at IS NULL
  AND s.email IS NULL
ORDER BY l.deal_value DESC
LIMIT 10;
