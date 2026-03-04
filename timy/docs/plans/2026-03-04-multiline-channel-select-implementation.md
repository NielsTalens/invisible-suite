# Multiline Channel Select Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update browser simulation to use fixed channel identities, multiline submission in one go, auto timestamps, and robust recognizer array normalization.

**Architecture:** Frontend sends `{channel, lines[]}` batch payload; backend maps channel->sender, writes one inbox record per line with current UTC timestamp, runs processor once, returns latest results.

**Tech Stack:** Sinatra, Ruby modules, vanilla JS, Minitest

---

### Task 1: Update API contract tests first
**Files:** `test/app_test.rb`, `test/ui_shell_test.rb`
1. Add failing tests for invalid channel, empty lines, and multiline write behavior.
2. Add UI test expectations for channel select and removal of sender/timestamp inputs.

### Task 2: Implement backend batch submit flow
**Files:** `app.rb`, `lib/timy/inbox_writer.rb`, `test/inbox_writer_test.rb`
1. Accept `channel` + `lines`.
2. Map channel to fixed sender values.
3. Write one inbox JSON per non-empty line with `Time.now.utc.iso8601`.
4. Keep one processing run per submit.

### Task 3: Update frontend form and submit payload
**Files:** `views/index.erb`, `public/app.js`, `public/styles.css` (if needed)
1. Replace fields with channel selector and multiline textarea.
2. Split textarea lines and send batch payload.

### Task 4: Fix recognizer array normalization
**Files:** `lib/timy/openai_recognizer.rb`, `test/openai_recognizer_test.rb`
1. Add failing test with array JSON response.
2. Normalize array payload to first hash entry.

### Task 5: Verify end-to-end
**Files:** `README.md` (if needed)
1. Run focused tests and full suite.
2. Update docs if payload changed materially.
