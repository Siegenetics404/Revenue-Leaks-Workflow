# 02 - AI Voice Receptionist for Missed Calls

Answers the calls your team can't pick up with an AI voice receptionist that collects the caller's details, checks a live schedule, and books the visit while the caller is still on the line. After each call, a local AI model turns the transcript into a summary and urgency rating, alerts the owner through the right channel, and texts back callers who hung up before saying anything. Every AI output is validated before anything acts on it, and bookings are enforced by the database, so the AI can never promise a slot that is already taken.

---

## What it does

**Workflow A: Post-Call Processing**
1. Receives Vapi's end-of-call report by webhook and ignores every other message type
2. Saves the call to Postgres under its unique call ID, so a replayed webhook is dropped instead of processed twice
3. Separates real conversations (at least two caller turns and 10 seconds) from hang-ups
4. For real conversations, a local LLM (via LM Studio) extracts the caller's name, the reason for calling, urgency, whether they want an appointment, whether a callback is needed, and a short summary
5. A validation layer checks the model's output before anything uses it. If extraction fails, the call fails safe: it is marked high urgency, flagged for a callback, and the raw transcript goes to the owner instead of being dropped
6. Routes by urgency:
   - **Emergency** → immediate Telegram alert to the owner
   - **Callback needed or high urgency** → callback alert with the summary and whether a visit was booked
   - **Routine** → saved to the database, no alert
7. If the AI booked a visit during the call, a booking confirmation goes to the caller (Telegram stands in for SMS)
8. Callers who hang up before speaking are checked against the suppression list and a 30-minute window, then get a single text-back, and the call is marked `hung_up`

**Workflow B: Live Booking Tools**

These are the two tools the AI calls while the caller is on the line. No LLM is involved, only SQL, so replies come back quickly.
1. **Check availability:** receives the requested date from Vapi and queries Postgres for open 30-minute slots (9 AM to 5 PM, Monday to Friday, in the future, not already booked)
2. Returns up to three times in Vapi's tool-result format, or tells the AI there are no openings so it can try another weekday
3. **Book appointment:** receives the chosen time, caller name, and reason
4. A guarded insert rejects times that are off-hours, on weekends, in the past, or off the 30-minute grid, and a unique constraint on the slot means a taken time inserts nothing
5. **Booked** → replies with the confirmed day and time and alerts the owner on Telegram
6. **Refused** → tells the AI to check availability again and offer other times

---

## Setup

Assumes the shared environment (Docker, n8n, LM Studio, shared credentials) from the repo root README is already running. You also need a free Vapi account and `cloudflared` installed.

### 1. Create this workflow's database

```bash
docker exec -it <postgres_container_name> psql -U n8n -c "CREATE DATABASE voice_receptionist;"
```

### 2. Create the tables

```bash
docker cp voice_receptionist_schema.sql <postgres_container_name>:/tmp/
docker exec -it <postgres_container_name> psql -U n8n -d voice_receptionist -f /tmp/voice_receptionist_schema.sql
```

This creates `calls`, `appointments`, and `suppression`.

### 3. Import the workflows

In n8n, import:
- `02 Voice Receptionist Post-Call.json`
- `02 Voice Receptionist Booking Tools.json`

### 4. Point credentials at this database

Every Postgres node needs the shared Postgres credential, with **database** set to `voice_receptionist`. The `Extract Data` node uses the shared LM Studio (OpenAI-compatible) credential, and every Telegram node needs the shared Telegram credential plus your chat ID.

### 5. Expose n8n to Vapi

Vapi runs in the cloud, so it needs a public URL to reach your local n8n:

```bash
cloudflared tunnel --url http://localhost:5678
```

Put the URL it prints in your `.env` as `WEBHOOK_URL=https://<your-tunnel>.trycloudflare.com/`, add `- WEBHOOK_URL=${WEBHOOK_URL}` to the n8n environment in `docker-compose.yml`, then recreate the container:

```bash
docker compose up -d n8n
```

The tunnel URL changes every time the tunnel restarts. When it does, update `WEBHOOK_URL` and the URLs in Vapi.

### 6. Publish both workflows

Vapi calls the production `/webhook/...` URLs, which only work while the workflows are published. The `/webhook-test/...` URLs stop working as soon as you stop listening in the editor.

### 7. Create the Vapi assistant

In the Vapi dashboard, create an assistant (inbound) and set:

- **First message:**
  ```
  Hi, you've reached Reyes Plumbing. We can't get to the phone right now, so I'm the virtual assistant. This call is transcribed so I can pass your message along. How can I help?
  ```
- **System prompt:** see below
- **Server URL** (Advanced → Messaging): `https://<your-tunnel>.trycloudflare.com/webhook/voice-receptionist`
- **Server Messages:** only `end-of-call-report`

Then create two **Function** tools (Async off) and attach both to the assistant:

| Tool | Description | Parameters | Server URL |
|---|---|---|---|
| `check_availability` | Get open appointment slots for a date. Call before offering any times. | `date` (string, required): `YYYY-MM-DD` | `.../webhook/check-availability` |
| `book_appointment` | Book an appointment slot. Only call this after the caller has picked one of the times returned by check_availability. | `date_time` (string, required): `YYYY-MM-DD HH:MM` in 24-hour local time; `caller_name` (string); `reason` (string) | `.../webhook/book-appointment` |

<details>
<summary>System prompt</summary>

```
You are the virtual receptionist for Reyes Plumbing, answering calls the team could not pick up. You are an AI, and you say so if asked.
Today is {{"now" | date: "%A, %Y-%m-%d", "Asia/Manila"}}. The business is on Manila time.

GOAL: capture who is calling, what they need, how urgent it is, and book a visit if they want one.

STYLE: This is a phone call. Two short sentences per turn at most. One question at a time. Plain words, no lists. Say times the way people say them (2 PM, not 14:00).

ALWAYS COLLECT: the caller's name, what is wrong, and the address or area for a visit.

BOOKING: If the caller wants a visit, ask which day works for them. Turn what they say into a date (YYYY-MM-DD) using today's date, then call check_availability for that date before saying anything about availability. Never suggest or mention a day or time that check_availability has not returned. If the caller has no preference, check the next weekday first and offer only what it returns.
If a day has no openings, say only that day is full, then check the next weekday yourself and offer its times. Try up to three weekdays before asking the caller for another day. Never say the week or month is full. The business takes visits Monday to Friday, 9 AM to 5 PM only.
Offer at most three times. When the caller picks one, call book_appointment with that date and time, then read back the day and time from the result. Never say a time is booked until book_appointment returns success. If book_appointment says the time is not available, call check_availability again and offer the new times.

EMERGENCIES: If the caller mentions a gas smell, fire, sparking, or anyone hurt, tell them to leave the area and call their local emergency number now, before anything else. For active flooding or a burst pipe, tell them to shut off the main water valve if it is safe, collect the address, and say the team is being alerted.

NEVER: quote prices, promise arrival times, diagnose problems, or state anything you were not told. If asked something outside your scope, say the team will follow up and take a message.

END: Summarize in one sentence, say the team will follow up, and end the call.
```

</details>

### 8. Run it

Use **Talk to Assistant** in the Vapi dashboard (a browser call, no phone number needed), and try:

- **A booking:** describe a leak, ask for a visit, and pick one of the offered times. A `[NEW BOOKING]` alert arrives during the call, and a confirmation follows after you hang up.
- **The refusal:** book the same time again and confirm the AI is told to offer other times.
- **An emergency:** say a pipe burst and confirm the `[EMERGENCY]` alert.
- **A hang-up:** browser calls have no phone number, so the text-back can't fire from one. Test it by POSTing a sample report with a `customer.number` to Workflow A:

```bash
curl -X POST https://<your-tunnel>.trycloudflare.com/webhook/voice-receptionist \
  -H "Content-Type: application/json" \
  -d '{"message":{"type":"end-of-call-report","startedAt":"2026-09-20T09:00:00.000Z","endedAt":"2026-09-20T09:00:06.000Z","endedReason":"customer-ended-call","artifact":{"transcript":"AI: Hello, you have reached Reyes Plumbing.\nUser: Hello?\n"},"call":{"id":"test-hangup-001","customer":{"number":"+639171234567"}}}}'
```

Use a new `call.id` each time you re-run it, or the duplicate guard will stop it.

---

## Schema

```sql
calls (
  id, call_id,       -- call_id is unique (Vapi call ID)
  caller_number, started_at, duration_sec, ended_reason,
  transcript, recording_url,
  caller_name, reason,
  urgency,           -- emergency | high | normal | low
  wants_appointment, callback_needed, summary,
  status,            -- new | handled | needs_review | hung_up
  followup_sent_at, created_at
)

appointments (
  id,
  slot_start,        -- unique, business local time
  caller_name, caller_number, reason, call_id,
  status, created_at
)

suppression ( number )
```

---

## Notes and limitations

- The demo runs as a browser call. To take real calls, forward the business line on no answer to a Vapi phone number. That part is not included.
- The voice layer runs on Vapi's free trial credits and bills per minute afterward. Everything else is free and self-hosted.
- Booking confirmations and hang-up text-backs go to Telegram as an SMS stand-in. Swap those two nodes for an SMS provider to text real callers.
- The webhooks are unauthenticated. Before using this beyond a demo, add Header Auth to each webhook and attach the matching credential in Vapi.
- Vapi records calls by default, and the recording URL is stored in `calls`. Turn recording off in the assistant's settings if you only need transcripts, and disclose recording and transcription to callers in the first message.
- Business hours (9 AM to 5 PM, Monday to Friday) and the `Asia/Manila` timezone are hardcoded in the SQL queries.
- Emergencies alert the owner, but there is no live call transfer.