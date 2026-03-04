# Browser Simulation UI Design

## Context
Timy currently runs as a Ruby CLI pipeline:
- Reads message JSON files from `inbox/`
- Uses OpenAI to structure entries
- Stores results in YAML
- Prints CLI output

This phase adds a browser simulation: single-page layout with input on the left and processing results on the right, while preserving the existing inbox-file workflow.

## Goals
- Provide a browser UI for entering messages.
- Persist each submitted message as a JSON file in `inbox/`.
- Trigger processing immediately on submit.
- Show refreshed processing results in the same page without full reload.

## Non-Goals
- Replacing the current processor architecture.
- Adding a full frontend framework.
- Introducing a database.

## UX Design
- Single page split into two panels:
  - Left panel: input form (`channel`, `sender`, `timestamp`, `message`)
  - Right panel: processing summary, structured entries, follow-up questions
- One-click flow:
  - User submits form
  - Backend writes inbox JSON
  - Backend runs processor
  - UI receives fresh results and re-renders right panel

## Architecture
- Add lightweight Sinatra app:
  - `GET /` -> serves HTML shell
  - `GET /api/results` -> returns latest YAML-derived results
  - `POST /api/submit-and-process` -> validates form, writes inbox JSON, runs processor, returns results JSON
- Reuse existing core modules (`InputLoader`, `OpenAiRecognizer`, `EntryValidator`, `YamlRepository`, `Processor`).
- Extend `Processor` to support non-CLI reporting mode (capture entries/summary without printing noise for API usage).

## Data and File Behavior
- New files written to `inbox/` using:
  - `<channel>-YYYY-MM-DD-<seq>.json`
- Processing keeps current behavior:
  - clear `data/timesheet_entries.yml` at run start
  - process all files in `inbox/` every run
- `data/processing_log.yml` remains append-style for run metadata.

## Validation and Errors
- API input validation:
  - required: `channel`, `sender`, `timestamp`, `message`
  - timestamp must be parseable ISO-8601
- Error contracts:
  - `422` for invalid request payload
  - `500` for processing failures, with readable error text
- Recognizer/parser fallbacks continue to populate `needs_clarification` entries.

## Frontend Technical Design
- Vanilla JS SPA behavior in a single HTML file.
- No page reloads after initial load.
- Fetch patterns:
  - on page load: `GET /api/results`
  - on submit: `POST /api/submit-and-process`, then render returned data
- Render sections:
  - summary counts (`processed`, `ok`, `needs_clarification`)
  - entry cards/table rows
  - dedicated follow-up list

## Testing Strategy
- Backend tests (Minitest):
  - route tests for `GET /api/results` and `POST /api/submit-and-process`
  - validation tests for bad payloads
  - file creation and naming tests for inbox JSON writing
  - integration test asserting submit triggers processing and returns updated entries
- Existing processor/module tests remain in place.

## Future Extension
- Add channel-specific presets/templates in UI.
- Add paging/filtering on results panel.
- Upgrade to richer frontend stack only if complexity grows.
