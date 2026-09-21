--
-- PostgreSQL database dump
--

\restrict SEuI0pZdQUsJGxbqJuPyDPoGUInMkIVGUburX45Fz2pNVheIOWmemaOPzfPlaUZ

-- Dumped from database version 16.15 (Debian 16.15-1.pgdg12+2)
-- Dumped by pg_dump version 16.15 (Debian 16.15-1.pgdg12+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appointments; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.appointments (
    id integer NOT NULL,
    slot_start timestamp without time zone NOT NULL,
    caller_name text,
    caller_number text,
    reason text,
    call_id text,
    status text DEFAULT 'booked'::text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.appointments OWNER TO n8n;

--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: n8n
--

CREATE SEQUENCE public.appointments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_id_seq OWNER TO n8n;

--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: n8n
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- Name: calls; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.calls (
    id integer NOT NULL,
    call_id text,
    caller_number text,
    started_at timestamp with time zone,
    duration_sec integer,
    ended_reason text,
    transcript text,
    recording_url text,
    caller_name text,
    reason text,
    urgency text,
    wants_appointment boolean,
    callback_needed boolean,
    summary text,
    status text DEFAULT 'new'::text,
    followup_sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.calls OWNER TO n8n;

--
-- Name: calls_id_seq; Type: SEQUENCE; Schema: public; Owner: n8n
--

CREATE SEQUENCE public.calls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.calls_id_seq OWNER TO n8n;

--
-- Name: calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: n8n
--

ALTER SEQUENCE public.calls_id_seq OWNED BY public.calls.id;


--
-- Name: email_log; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.email_log (
    id integer NOT NULL,
    lead_id integer,
    touch_number integer,
    subject text,
    body text,
    validation_pass boolean,
    validation_fail text,
    sent_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.email_log OWNER TO n8n;

--
-- Name: email_log_id_seq; Type: SEQUENCE; Schema: public; Owner: n8n
--

CREATE SEQUENCE public.email_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_log_id_seq OWNER TO n8n;

--
-- Name: email_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: n8n
--

ALTER SEQUENCE public.email_log_id_seq OWNED BY public.email_log.id;


--
-- Name: leads; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.leads (
    id integer NOT NULL,
    first_name text NOT NULL,
    last_name text,
    company text NOT NULL,
    email text NOT NULL,
    industry text,
    last_purchase_date date,
    last_contact_date date,
    deal_value numeric(10,2) DEFAULT 0,
    lost_reason text,
    status text DEFAULT 'dead'::text NOT NULL,
    touch_count integer DEFAULT 0 NOT NULL,
    next_touch_at timestamp without time zone,
    last_sent_subject text,
    last_sent_body text,
    replied_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT status_values CHECK ((status = ANY (ARRAY['dead'::text, 'in_reactivation'::text, 'replied'::text, 'exhausted'::text, 'unsubscribed'::text])))
);


ALTER TABLE public.leads OWNER TO n8n;

--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: n8n
--

CREATE SEQUENCE public.leads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leads_id_seq OWNER TO n8n;

--
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: n8n
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


--
-- Name: suppression; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.suppression (
    number text NOT NULL
);


ALTER TABLE public.suppression OWNER TO n8n;

--
-- Name: suppression_list; Type: TABLE; Schema: public; Owner: n8n
--

CREATE TABLE public.suppression_list (
    email text NOT NULL,
    reason text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.suppression_list OWNER TO n8n;

--
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- Name: calls id; Type: DEFAULT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.calls ALTER COLUMN id SET DEFAULT nextval('public.calls_id_seq'::regclass);


--
-- Name: email_log id; Type: DEFAULT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.email_log ALTER COLUMN id SET DEFAULT nextval('public.email_log_id_seq'::regclass);


--
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.appointments (id, slot_start, caller_name, caller_number, reason, call_id, status, created_at) FROM stdin;
1	2026-09-22 10:00:00	CJ	+639171234567	Kitchen sink leak	test-call-001	booked	2026-09-20 10:06:03.651466+00
3	2026-09-22 11:00:00	Maria	+639181112222	Clogged drain	test-call-003	booked	2026-09-20 10:20:09.018361+00
4	2026-09-23 09:00:00	Maria	+639181112222	Clogged drain	test-call-101	booked	2026-09-20 12:27:34.051842+00
5	2026-09-21 09:30:00	CJ	web-call	leaking kitchen	01a0beca-8687-7000-8387-8961b2b18a7b	booked	2026-09-20 12:29:57.039318+00
\.


--
-- Data for Name: calls; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.calls (id, call_id, caller_number, started_at, duration_sec, ended_reason, transcript, recording_url, caller_name, reason, urgency, wants_appointment, callback_needed, summary, status, followup_sent_at, created_at) FROM stdin;
8	01a0bdf7-657f-711d-b469-4a951c07ac50	web-call	2026-09-20 08:38:22.819+00	52	customer-ended-call	AI: Hello,.\nUser: Leaking.\nAI: I'm sorry to hear that. May I have your name, please?\nUser: CJ.\nAI: Thank you, CJ. Can you tell me what is leaking and where it is happening?\nUser: In my— Kitchen.\nAI: Thanks, CJ. Which area or address should the team visit for your kitchen leak?\nUser: No thanks.\nAI: No problem, CJ. Would you like any advice or for the team to call you back about your kitchen leak?\nUser: Not at all.\nAI: Thank you for letting us know, CJ. If you need help in the future, please feel free to call again. Have a good day.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0bdf7-657f-711d-b469-4a951c07ac50-1789893557790-a1a76ba2-892a-4aa7-a900-7df50a20b639-mono.wav	CJ	Leaking kitchen	high	f	t	CJ needs advice on handling the leak himself.	handled	\N	2026-09-20 09:15:35.879026+00
9	test-hangup-001	+639171234567	2026-09-20 09:00:00+00	6	customer-ended-call	AI: Hello, you have reached Reyes Plumbing.\nUser: Hello?\n		\N	\N	\N	\N	\N	\N	hung_up	2026-09-20 09:36:37.260834+00	2026-09-20 09:35:37.581884+00
10	test-hangup-002	+639171234567	2026-09-20 09:40:00+00	5	customer-ended-call	AI: Hello, you have reached Reyes Plumbing.\nUser: Hello?\n		\N	\N	\N	\N	\N	\N	new	\N	2026-09-20 09:40:07.298693+00
11	01a0beb6-9fab-7dd6-b0c7-7963bf36272f	web-call	2026-09-20 12:07:15.149+00	137	customer-ended-call	AI: Hello,.\nUser: Hello.\nAI: Hi, thank you for calling Reyes Plumbing. May I have your name, please?\nUser: CJ?\nAI: Thank you, CJ. What plumbing issue can I help you with today?\nUser: I think it's leaking.\nAI: Thanks for letting me know, CJ. Can you tell me where you are located or where the leak is happening?\nUser: I'm— From Talisay City.\nAI: Thank you, CJ. Would you like to book a visit for our team to check the leak?\nUser: Yes, what time are you available?\nAI: It looks like we don't have any openings for tomorrow. Is there another day that works for you?\nAI: Maybe Tuesday, or later this week?\nUser: How about the day before? I have the day. Tomorrow.\nAI: I'm sorry, CJ, but we don't have any slots left for today or tomorrow. Would you like to try Wednesday or another day this week?\nUser: Okay, let's go Wednesday.\nAI: CJ, it looks like Wednesday is also fully booked. Would Thursday or Friday work for you?\nUser: Let's go. Thursday.\nAI: Thursday is also fully booked, CJ. Would Friday be okay for you?\nUser: Friday then.\nAI: CJ, I'm sorry, but Friday is also fully booked. Would you like to try Saturday or Sunday next week?\nUser: What day? It's not available.\nAI: It looks—\nUser: This month.\nAI: It looks like we are fully booked for the rest of this week. Would you like to try booking for next week instead?\nUser: Yes. Monday.\nAI: CJ, Monday next week is also fully booked. Would you like to try Tuesday or another day?\nUser: No. Let's end this.\nAI: Thank you, CJ. I've noted your request and the team will follow up as soon as a slot is available. Have a good day.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0beb6-9fab-7dd6-b0c7-7963bf36272f-1789906174266-79234357-116c-46b8-bee2-7f62b6a301a9-mono.wav	CJ	Leaking issue	normal	t	t	Cannot book an appointment this month; all days are fully booked.	handled	\N	2026-09-20 12:09:36.281224+00
12	01a0beca-8687-7000-8387-8961b2b18a7b	web-call	2026-09-20 12:28:59.401+00	77	customer-ended-call	AI: Hello,.\nUser: Hello,.\nAI: Hello, this is Reyes Plumbing's virtual receptionist. May I have your name, please?\nUser: My name is CJ, and I need assistance for my— Leaking. Kitchen.\nAI: Thank you, CJ. Could you please tell me the address or area where you need help with your leaking kitchen?\nUser: Talisay.\nAI: Thank you, CJ. Would you like to book a visit for your leaking kitchen in Talisay?\nUser: What date are. You available?\nAI: We have openings tomorrow, Monday, at 9:00 AM, 9:30 AM, or 10:00 AM. Which time would you prefer? CJ?\nUser: Let's do. Monday. At 9:30 AM.\nAI: You are booked for Monday at 9:30 AM for your leaking kitchen in Talisay. The team will follow up with you; thank you for calling, CJ. Goodbye.\nUser: Thanks.\nAI: You're all set for Monday at 9:30 AM. The team will follow up; thank you, CJ. Goodbye.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0beca-8687-7000-8387-8961b2b18a7b-1789907419290-3510b982-6591-4bd3-aeff-36be65447b19-mono.wav	CJ	Leaking kitchen in Talisay	normal	t	f	Booked a visit for Monday at 9:30 AM for a leaking kitchen in Talisay.	handled	\N	2026-09-20 12:30:21.132219+00
13	01a0bed0-97e9-7774-b92d-8d2efce864a0	web-call	2026-09-20 12:35:36.991+00	53	customer-ended-call	AI: Hello,.\nUser: My pipe burst—\nAI: I'm sorry to hear that. If it is safe, please shut off your main water valve to stop the flooding. May I have your name and the address where this happened?\nUser: My name is CJ, and this. Happened. In the kitchen, and I'm in Talisay.\nAI: Thank you, CJ. The team is being alerted about your burst pipe in the kitchen in Tellisse. Can you tell me how urgent the situation is right now?\nUser: It's very urgent.\nAI: Thank you for letting me know, CJ. The team will follow up with you as soon as possible about your urgent burst pipe in your Talisay kitchen. Ending the call now.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0bed0-97e9-7774-b92d-8d2efce864a0-1789907792623-d5b8dee2-bd4e-4ef2-8824-f935e2874b3e-mono.wav	\N	extraction failed, read transcript	high	f	t	AI: Hello,.\nUser: My pipe burst—\nAI: I'm sorry to hear that. If it is safe, please shut off your main water valve to stop the flooding. May I have your name and the address where this happened?\nUser: My name is CJ, and this. Happened. In the kitchen, and I'm in Talisay.\nAI: Thank you, CJ. The team i	needs_review	\N	2026-09-20 12:36:34.433186+00
14	test-emergency-001	+639171234567	2026-09-20 13:00:00+00	70	customer-ended-call	AI: Hello, this is the Reyes Plumbing virtual receptionist.\nUser: My pipe burst in the kitchen and there is water everywhere.\nAI: I am sorry to hear that. If it is safe, please shut off your main water valve. May I have your name and address?\nUser: My name is CJ and I am in Talisay.\nAI: Thank you, CJ. The team is being alerted. How urgent is it?\nUser: It is very urgent.\nAI: The team will follow up as soon as possible.\n		CJ	Pipe burst in the kitchen.	emergency	f	t	Main water valve needs to be shut off immediately due to a burst pipe.	handled	\N	2026-09-20 12:39:50.638899+00
15	01a0bed5-b14b-7000-83a9-3d86dd657dbe	web-call	2026-09-20 12:41:11.229+00	89	customer-ended-call	AI: Hello,.\nUser: Verse 5.\nAI: Hi, this is Reyes Plumbing's virtual receptionist. Could you tell me your name and what you need help with today?\nUser: My name is CJ, and my 5. Verse in my kitchen—\nAI: Thank you. Thank you, CJ. Could you tell me more about what is happening with your kitchen? Are you having a leak, blockage, or something else?\nUser: My 5 verse—\nAI: Just to clarify, C. J., are you referring to a plumbing issue, like a burst pipe, leak, or something else in your kitchen? Could you describe what you-.\nUser: Yes.\nAI: Thank you for.\nUser: Verse 5, lick.\nAI: Thank you for sharing that, CJ. Just to confirm, is there water leaking in your kitchen right now?\nUser: Yes.\nAI: Thanks for confirming, CJ. Could you please tell me your address or area so we can assist you?\nUser: Talisay City, Tobangan.\nAI: Thank you, CJ. Would you like to book a visit from our team to check the leak in your kitchen?\nUser: No. Thanks.\nAI: Thank you, CJ. I've noted your concern, and the team will follow up with you soon. Have a good day.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0bed5-b14b-7000-83a9-3d86dd657dbe-1789908162680-fbd8ef33-191b-4a2a-a16f-f654b410c96f-mono.wav	CJ	Water leaking in Verse 5 of their kitchen.	emergency	f	t	Leaking issue in kitchen needs urgent attention at Talisay City, Tobangan.	handled	\N	2026-09-20 12:42:44.567512+00
16	01a0bed8-8941-7774-b945-cb205532de6a	web-call	2026-09-20 12:44:17.598+00	74	customer-ended-call	AI: Hello,.\nUser: It's an emergency.\nAI: I'm here to help. Can you please tell me what kind of emergency you're having?\nUser: My kitchen is leaking.\nAI: I'm sorry to hear that. Is there active flooding or a burst pipe, or is it a smaller leak?\nUser: I think it's a burst pipe.\nAI: If it's safe, please shut off your main water valve right away to stop the flooding. Can you tell me your address so the team can respond?\nUser: I can't shut it off. I'm at my address in Stalisay City.\nAI: Thank you. Thank you for letting me know. The team is being alerted about your burst pipe in Stalisay City. Can I have your name, please?\nUser: CJ.\nAI: Thank you, CJ. Can you tell me if anyone is hurt or if there's any danger, like sparking or a gas smell?\nUser: No.\nAI: Thank you for confirming. The team will follow up with you soon about the burst pipe in your kitchen in Stalisay City. Goodbye.\n	https://94bdb67bb98da30b06bdd917725c037d.r2.cloudflarestorage.com/hipaa-recordings/01a0bed8-8941-7774-b945-cb205532de6a-1789908333863-09d99636-3218-48cf-8a4f-bf528259d2e9-mono.wav	CJ	Kitchen is leaking due to what appears to be a burst pipe.	emergency	f	t	Caller's kitchen has active flooding from a burst pipe. Crew will follow up.	handled	\N	2026-09-20 12:45:35.856236+00
\.


--
-- Data for Name: email_log; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.email_log (id, lead_id, touch_number, subject, body, validation_pass, validation_fail, sent_at) FROM stdin;
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.leads (id, first_name, last_name, company, email, industry, last_purchase_date, last_contact_date, deal_value, lost_reason, status, touch_count, next_touch_at, last_sent_subject, last_sent_body, replied_at, created_at, updated_at) FROM stdin;
2	Priya	Raghavan	Nordwell Interiors	franco.cj03+lead02@gmail.com	Interior Design	2023-11-20	2024-01-15	12500.00	Budget was cut mid-project, never resumed	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
3	Tom	Alderton	Alderton Heating Services	franco.cj03+lead03@gmail.com	HVAC	\N	2024-05-22	3200.00	Ghosted after the proposal, no reason given	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
5	Dean	Okafor	Okafor Electrical	franco.cj03+lead05@gmail.com	Electrical	\N	2025-01-08	1800.00	Said they would think about it and never came back	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
6	Helen	Brightwater	Brightwater Landscaping	franco.cj03+lead06@gmail.com	Landscaping	2024-06-01	2025-08-14	6700.00	Decided to handle it in house	in_reactivation	1	2026-09-16 10:33:29.11265	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
7	Raj	Patel	Patel Property Group	franco.cj03+lead07@gmail.com	Property	\N	2025-07-30	34000.00	Project was shelved when their funding fell through	in_reactivation	1	2026-09-17 10:33:29.11265	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
8	Fiona	Mackenzie	Mackenzie Joinery	franco.cj03+lead08@gmail.com	Carpentry	2023-04-19	2025-09-02	4900.00	Never responded to the revised quote	in_reactivation	2	2026-09-15 10:33:29.11265	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
11	Owen	Tremaine	Tremaine Builders	franco.cj03+lead11@gmail.com	Construction	2024-09-09	2025-09-01	18900.00	Paused after phase one	replied	1	2026-09-13 10:33:29.11265	\N	\N	2026-09-15 10:33:29.11265	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
12	Grace	Lindqvist	Lindqvist Flooring	franco.cj03+lead12@gmail.com	Flooring	\N	2025-06-18	5300.00	Asked to be removed from all lists	unsubscribed	1	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
14	Iris	Delacroix	Delacroix Design Studio	franco.cj03+lead14@gmail.com	Design	\N	2025-09-15	9600.00	Wanted to revisit in the new financial year	in_reactivation	1	2026-09-21 10:33:29.11265	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
16	Amara	Nwosu	Nwosu Cleaning Services	franco.cj03+lead16@gmail.com	Cleaning	2024-01-05	2024-02-20	900.00	Too expensive for a monthly retainer	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
17	Lars	Bergstrom	Bergstrom Windows	franco.cj03+lead17@gmail.com	Windows	\N	2023-12-01	11400.00	Preferred a supplier with a longer warranty	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
18	Chloe	Ashworth	Ashworth Bathrooms	franco.cj03+lead18@gmail.com	Bathrooms	2024-07-22	2024-08-30	7200.00	Renovation postponed indefinitely	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
21	Erik	Solheim	Solheim Marine	franco.cj03+lead21@gmail.com	Marine	\N	2025-05-09	13800.00	\N	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
22	Maeve	O'Sullivan	O'Sullivan & Daughters	franco.cj03+lead22@gmail.com	Construction	2024-03-17	2024-04-25	5600.00	Preferred to work with a firm they had used before	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
24	Nina	Kovacs	Kovacs Signage	franco.cj03+lead24@gmail.com	Signage	\N	2025-08-01	0.00	Enquiry only, never quoted	dead	0	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
15	Viktor	Ivanov	Ivanov Commercial Fitouts	cjfranco00@gmail.com	Commercial	\N	2026-09-18	87000.00	Went quiet after the site survey	in_reactivation	1	2026-12-17 10:35:21.106342	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
1	Marcus	Whitfield	Whitfield Plumbing Ltd	franco.cj03+lead01@gmail.com	Home Services	2024-02-11	2026-09-18	8400.00	Went with a cheaper local competitor	in_reactivation	1	2026-09-22 12:53:10.214517	\N	Hi Marcus, Whitfield Plumbing Ltd was referred to us with great confidence. It's been 928 days since we last spoke and I'm reaching out to see if the issue that led you to switch to a cheaper competitor is still troubling you today? We'd love the chance to address it.	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
23	Hugo	Vasquez	Vasquez Restoration	franco.cj03+lead23@gmail.com	Restoration	2021-06-14	2026-09-18	19500.00	Project completed, no follow up work booked	in_reactivation	1	2026-09-22 12:53:27.566092	\N	Hi Hugo, it's been quite some time since we last connected. Wondering how that project turned out for you? Have you completed all your restoration work without any further need for our services? Curious if there are ongoing issues or challenges you're addressing. CJ	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
19	Samuel	Kirui	Kirui Groundworks	franco.cj03+lead19@gmail.com	Groundworks	\N	2026-09-18	26500.00	Lost the tender to a larger firm	in_reactivation	1	2026-09-22 12:53:45.313721	\N	Hi Samuel, Kirui Groundworks! I hope you're well and thriving. It's been some time since we last spoke—581 days to be precise. We lost the tender to a larger firm but I'm keen to see if the issue is still on your plate. Can you let me know what your current plans are? CJ	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
20	Yuki	Tanaka	Tanaka Architectural	franco.cj03+lead20@gmail.com	Architecture	\N	2026-09-18	41000.00	Client changed direction after concept stage	in_reactivation	1	2026-09-22 12:53:53.248617	\N	Hi Yuki, I hope you're well. We noticed we haven't spoken since 539 days ago when your project's direction changed during the concept stage. The value of that potential deal was $41,000. Is this still on your radar? Let me know if this issue is still relevant for you.	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
4	Sofia	Marchetti	Bellacasa Kitchens	franco.cj03+lead04@gmail.com	Kitchen Fitting	2023-08-30	2026-09-18	21000.00	Timeline was too long, needed it before Christmas	in_reactivation	1	2026-09-22 12:53:36.844755	\N	Hi Sofia, it's been quite some time since we last spoke about your kitchen project. The timeline was too long for you, and I remember you needed everything before Christmas. Have you found a solution? Hoping this email finds you well. Let me know if this is still on your plate.	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
10	Nadia	Fischer	Fischer Glazing	franco.cj03+lead10@gmail.com	Glazing	\N	2025-09-10	2400.00	Not interested in the upsell	exhausted	3	2026-09-17 10:33:29.11265	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
13	Bilal	Hassan	Hassan Tiling	franco.cj03+lead13@gmail.com	Tiling	\N	2025-04-02	2100.00	No budget this year	exhausted	3	\N	\N	\N	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
9	Callum	Reed	Reed Roofing Co	franco.cj03+lead09@gmail.com	Roofing	\N	2026-09-18	15200.00	Chose a contractor their insurer recommended	exhausted	3	2026-09-22 12:53:20.437586	\N	Hi Callum, Reed Roofing Co went with a contractor their insurer recommended instead of us. That's understandable! How are things going? Would you be open to reconnecting if opportunities arise in the future? reply 'no' and I'll close your file.	\N	2026-09-18 10:33:29.11265	2026-09-18 10:33:29.11265
\.


--
-- Data for Name: suppression; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.suppression (number) FROM stdin;
\.


--
-- Data for Name: suppression_list; Type: TABLE DATA; Schema: public; Owner: n8n
--

COPY public.suppression_list (email, reason, created_at) FROM stdin;
franco.cj03+lead12@gmail.com	Requested removal by reply, 2025-06-18	2026-09-18 10:33:29.12011
franco.cj03+blocked01@gmail.com	Bounced 3 times	2026-09-18 10:33:29.12011
franco.cj03+blocked02@gmail.com	Marked as spam	2026-09-18 10:33:29.12011
cjfranco00@gmail.com	Requested via reply, 2026-09-18	2026-09-18 10:42:19.656044
\.


--
-- Name: appointments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: n8n
--

SELECT pg_catalog.setval('public.appointments_id_seq', 5, true);


--
-- Name: calls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: n8n
--

SELECT pg_catalog.setval('public.calls_id_seq', 16, true);


--
-- Name: email_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: n8n
--

SELECT pg_catalog.setval('public.email_log_id_seq', 1, false);


--
-- Name: leads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: n8n
--

SELECT pg_catalog.setval('public.leads_id_seq', 24, true);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_slot_start_key; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_slot_start_key UNIQUE (slot_start);


--
-- Name: calls calls_call_id_key; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_call_id_key UNIQUE (call_id);


--
-- Name: calls calls_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: email_log email_log_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_pkey PRIMARY KEY (id);


--
-- Name: leads leads_email_key; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_email_key UNIQUE (email);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: suppression_list suppression_list_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.suppression_list
    ADD CONSTRAINT suppression_list_pkey PRIMARY KEY (email);


--
-- Name: suppression suppression_pkey; Type: CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.suppression
    ADD CONSTRAINT suppression_pkey PRIMARY KEY (number);


--
-- Name: idx_leads_due; Type: INDEX; Schema: public; Owner: n8n
--

CREATE INDEX idx_leads_due ON public.leads USING btree (status, touch_count, next_touch_at);


--
-- Name: email_log email_log_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: n8n
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict SEuI0pZdQUsJGxbqJuPyDPoGUInMkIVGUburX45Fz2pNVheIOWmemaOPzfPlaUZ

