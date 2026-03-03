# Timy Phase 1 Prototype

Ruby CLI prototype that ingests JSON messages from `inbox/`, structures timesheet entries via OpenAI, stores results in YAML, and prints a processing report.

## Setup

1. Copy `.env.example` to `.env`.
2. Set `OPENAI_API_KEY` in `.env`.
3. (Optional) Set `OPENAI_MODEL` in `.env`.

## Input format

Add one JSON file per message in `inbox/` with fields:

- `channel`
- `sender`
- `timestamp` (ISO-8601)
- `message`

Example:

```json
{
  "channel": "email",
  "sender": "nelis",
  "timestamp": "2026-03-01T09:00:00Z",
  "message": "Spent 2.5h on project Alpha preparing sprint planning"
}
```

## Run

```bash
ruby bin/process_messages
```

## Output files

- `data/timesheet_entries.yml`
- `data/processing_log.yml`

## Test

```bash
ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |f| require_relative f }'
```
