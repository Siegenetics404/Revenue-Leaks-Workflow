-- Reference data the winback emails depend on
INSERT INTO offers VALUES
  ('PRICE','WB20','20% off for your first 3 months back',20),
  ('NOT_USING','ONBOARD','a free 30-minute setup call',0),
  ('SUPPORT_BAD','MGRCALL','a direct line to our support manager',0),
  ('MISSING_FEATURE',NULL,'see what has shipped since you left',0)
ON CONFLICT (reason) DO NOTHING;

INSERT INTO product_updates (released_at, title, summary) VALUES
  (CURRENT_DATE - 20, 'Bulk import', 'Import customers from CSV in one step'),
  (CURRENT_DATE - 10, 'Custom reports', 'Build and schedule your own reports'),
  (CURRENT_DATE - 3,  'Slack integration', 'Get alerts in Slack channels');

-- Demo customers (every 4th is declining). Change the email address before real use.
INSERT INTO customers (first_name, company, email, plan, mrr, signup_date, renewal_date, last_login_at)
SELECT 'User'||g, 'Company '||g, 'franco.cj03+u'||g||'@gmail.com',
  (ARRAY['starter','pro','business'])[1+g%3],
  (ARRAY[49,199,799])[1+g%3],
  CURRENT_DATE - (g*20),
  CURRENT_DATE + (g*3 % 90),
  CASE WHEN g%4=0
       THEN NOW() - ((12+random()*28)||' days')::interval
       ELSE NOW() - ((random()*6)||' days')::interval END
FROM generate_series(1,30) g;

INSERT INTO usage_weekly
SELECT c.id,
  (date_trunc('week', CURRENT_DATE) - (w*7||' days')::interval)::date,
  (CASE WHEN c.id%4=0 AND w<4 THEN random()*3 ELSE 5+random()*10 END)::int,
  (CASE WHEN c.id%4=0 AND w<4 THEN random()*5 ELSE 20+random()*20 END)::int
FROM customers c, generate_series(0,11) w;

INSERT INTO support_tickets (customer_id, created_at, sentiment, subject)
SELECT id, NOW() - interval '5 days', 'negative', 'Reports not loading'
FROM customers WHERE id%8=0;

INSERT INTO churn_invoices (customer_id, due_date, status, amount)
SELECT id, CURRENT_DATE - 10, 'failed', mrr
FROM customers WHERE id%12=0;