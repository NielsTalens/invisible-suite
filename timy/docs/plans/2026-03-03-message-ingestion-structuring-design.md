# Message Ingestion and Structuring Design

## Context
Phase 1 focuses on simulated multi-channel intake via files. Messages are recognized with the OpenAI API, mapped into a structured timesheet schema, saved locally, and displayed in CLI output.

## Goals
- Accept JSON message files with channel metadata.
- Extract structured timesheet records from natural language.
- Flag unclear entries and generate follow-up questions.
- Persist results in a simple local datastore.
- Print processing results for immediate inspection.

## Non-Goals (Phase 1)
- Real channel integrations (email/WhatsApp/Signal APIs).
- Multi-user auth or permissions.
- External database setup (Postgres/MySQL).
- Rich UI (web dashboard).

## Inputs
- Directory: `inbox/`
- One JSON file per message
- Required JSON fields:
  - `channel`
  - `sender`
  - `timestamp`
  - `message`

Processing order is by `timestamp` ascending to keep deterministic runs.

## Architecture
- Runtime: Ruby CLI app.
- Pipeline:
  1. Discover input files in `inbox/`.
  2. Validate input JSON shape.
  3. Send normalization request to OpenAI.
  4. Validate and normalize model output.
  5. Persist record into YAML datastore.
  6. Print summary and follow-up questions.

Core modules:
- `InputLoader`: reads and validates incoming JSON files.
- `OpenAiRecognizer`: calls OpenAI and requests strict JSON output.
- `EntryValidator`: enforces output schema and fallback behavior.
- `YamlRepository`: appends entries and logs processing metadata.
- `CliReporter`: renders results in terminal.

## Structured Output Schema
Each processed message yields one entry with:
- `source_file`
- `channel`
- `sender`
- `original_timestamp`
- `work_date`
- `project`
- `task_description`
- `duration_hours`
- `confidence` (`high|medium|low`)
- `status` (`ok|needs_clarification`)
- `clarification_question` (required when `needs_clarification`)

## OpenAI Prompting Strategy
- System prompt enforces schema and output-only JSON.
- User payload includes original message plus metadata.
- Deterministic settings where possible to reduce drift.
- If model output is malformed or incomplete:
  - mark `status: needs_clarification`
  - set `clarification_question` fallback text
  - include processing note in log

## Persistence
- `data/timesheet_entries.yml`: append-only list of structured entries.
- `data/processing_log.yml`: run metadata and processing errors/fallback reasons.

YAML is intentionally chosen for fast iteration and inspectability. Repository interfaces should allow swapping to SQLite later.

## CLI Display
After processing:
- total messages processed
- `ok` count
- `needs_clarification` count
- list of entries (compact row output)
- separate follow-up section for unclear items

## Configuration and Secrets
- `.env` contains `OPENAI_API_KEY`.
- `.env.example` committed.
- App fails fast with actionable error if key is missing.

## Error Handling
- Invalid input file shape: skip file, log error.
- OpenAI request failure: log and create `needs_clarification` fallback entry.
- Invalid model JSON: fallback `needs_clarification`.
- Storage failure: fail run with clear error message.

## Testing Strategy
TDD-first implementation:
- Unit tests:
  - input JSON validation
  - output schema validation
  - fallback on malformed model output
- Integration-style test:
  - end-to-end processing with mocked OpenAI response
  - verifies YAML persistence and reporter output summary

## Future Extension Path
- Replace YAML repository with SQLite adapter.
- Add channel connectors while preserving normalized ingestion interface.
- Add corrections flow on top of existing structured records.
