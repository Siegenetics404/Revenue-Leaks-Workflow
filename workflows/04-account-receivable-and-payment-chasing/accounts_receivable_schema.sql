-- Accounts Receivable & Payment Chasing schema + seed data

CREATE TABLE IF NOT EXISTS invoices (
  id SERIAL PRIMARY KEY,
  client_name TEXT,
  company TEXT,
  email TEXT,
  invoice_number TEXT UNIQUE,
  amount NUMERIC,
  currency TEXT DEFAULT 'USD',
  issued_date DATE,
  due_date DATE,
  status TEXT DEFAULT 'unpaid',
  escalation_stage INT DEFAULT 0,
  last_contact_date DATE,
  next_action_at TIMESTAMP,
  last_sent_body TEXT,
  promised_pay_date DATE,
  paid_at TIMESTAMP,
  dispute_flag BOOLEAN DEFAULT FALSE,
  notes TEXT
);

INSERT INTO invoices (client_name, company, email, invoice_number, amount, due_date, issued_date)
VALUES
('Marco Reyes', 'Kestrel Digital Solutions', 'test+marco@example.com', 'INV-1001', 1200, CURRENT_DATE + 5, CURRENT_DATE - 25),
('Priya Nandan', 'Lakeview OBPLS', 'test+priya@example.com', 'INV-1002', 3400, CURRENT_DATE - 5, CURRENT_DATE - 35),
('Tom Fletcher', 'Northgate Fleet', 'test+tom@example.com', 'INV-1003', 850, CURRENT_DATE - 15, CURRENT_DATE - 45),
('Elena Cruz', 'Hocu Heating Services', 'test+elena@example.com', 'INV-1004', 2100, CURRENT_DATE - 50, CURRENT_DATE - 80)
ON CONFLICT (invoice_number) DO NOTHING;
