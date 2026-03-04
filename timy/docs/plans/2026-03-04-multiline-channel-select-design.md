# Multiline Input and Fixed Channel Identity Design

## Context
The browser simulation currently accepts free-form channel/sender/timestamp inputs and one message per submit. You requested:
- fixed demo identities per channel
- no user-entered timestamp (use `Time.now`)
- multiline input support
- clean handling for model array outputs (`Recognizer returned Array`)

## Goals
- Replace free-form sender/channel behavior with a controlled channel selector.
- Convert multiline textarea input into multiple message records per submit.
- Keep existing inbox JSON + processor pipeline intact.
- Prevent recognizer array output from degrading into avoidable fallback errors.

## UI Design
- Input form fields:
  - `Channel` select with exact mappings:
    - `Mail` -> `niels@example.com`
    - `SMS` -> `+3165892356`
    - `WhatsApp` -> `+3156455645`
  - `Message` textarea (multiline)
- Removed fields:
  - manual sender
  - manual timestamp
- Submit behavior:
  - split textarea by newline
  - trim lines
  - ignore blank lines
  - send one batch payload in one request

## API Design
- Keep `POST /api/submit-and-process` endpoint.
- Updated payload contract:
  - `channel`: one of `mail`, `sms`, `whatsapp`
  - `lines`: array of non-empty message strings
- Server behavior:
  - map channel to fixed sender
  - for each line write one inbox JSON record
  - assign `timestamp = Time.now.utc.iso8601`
  - run processor once after writing all records
  - return latest summary and entries
- Validation:
  - 422 if invalid channel
  - 422 if no valid lines after trim

## Data and Processing Behavior
- Inbox filenames continue sequence pattern:
  - `<channel>-YYYY-MM-DD-<seq>.json`
- Existing clear-before-run entry behavior remains unchanged.

## Recognizer Robustness
- If model response parses to an array:
  - use first hash element as recognized payload
  - otherwise fallback with recognizer error metadata
- Entry validator remains defensive guard for non-hash values.

## Testing Strategy
- API tests:
  - rejects invalid channel
  - rejects empty lines
  - writes one inbox file per non-empty line
  - uses fixed sender mapping
- Inbox writer tests:
  - accepts explicit timestamp override for deterministic file naming in tests
- Recognizer tests:
  - array response normalizes to first hash entry
- UI shell tests:
  - channel select present
  - no sender/timestamp input fields
