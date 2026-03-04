# Browser Simulation UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a browser-based single page interface with left-side message input and right-side processing results, while preserving inbox JSON files and immediate processing on submit.

**Architecture:** Sinatra serves a single-page UI and JSON endpoints. Submit endpoint writes inbox JSON and runs the existing processor pipeline. Result endpoint reads current YAML output. Frontend uses vanilla JS fetch calls for no-reload interaction.

**Tech Stack:** Ruby, Sinatra, Minitest, Rack::Test, existing Timy modules, vanilla JavaScript, CSS

---

### Task 1: Add Web Runtime Dependencies and Test Harness

**Files:**
- Modify: `Gemfile`
- Modify: `test/test_helper.rb`
- Create: `test/app_test.rb`

**Step 1: Write the failing test**

```ruby
def test_root_route_returns_success; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/app_test.rb`
Expected: FAIL because `app.rb`/Sinatra app is missing.

**Step 3: Write minimal implementation**

- Add `sinatra` and `rack-test` to `Gemfile`.
- Add Rack::Test setup in `test/test_helper.rb`.
- Minimal `app.rb` placeholder with `get "/"`.

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/app_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add Gemfile test/test_helper.rb app.rb test/app_test.rb
git commit -m "feat: scaffold sinatra app and test harness"
```

### Task 2: Build API for Reading Current Results

**Files:**
- Modify: `app.rb`
- Create: `lib/timy/results_reader.rb`
- Create: `test/results_reader_test.rb`
- Modify: `test/app_test.rb`

**Step 1: Write the failing test**

```ruby
def test_api_results_returns_summary_and_entries; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/app_test.rb`
Expected: FAIL because `/api/results` route does not exist.

**Step 3: Write minimal implementation**

- Implement `ResultsReader` to read `data/timesheet_entries.yml`.
- Add `GET /api/results` route returning JSON:
  - `summary`: processed, ok, needs_clarification
  - `entries`: current entries array

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/results_reader_test.rb`
Run: `ruby -Itest test/app_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add app.rb lib/timy/results_reader.rb test/results_reader_test.rb test/app_test.rb
git commit -m "feat: add api endpoint for current processing results"
```

### Task 3: Implement Submit-and-Process API

**Files:**
- Create: `lib/timy/inbox_writer.rb`
- Modify: `app.rb`
- Modify: `lib/timy.rb`
- Create: `test/inbox_writer_test.rb`
- Modify: `test/app_test.rb`

**Step 1: Write the failing test**

```ruby
def test_submit_and_process_writes_inbox_file_and_returns_results; end
def test_submit_and_process_rejects_invalid_payload; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/app_test.rb`
Expected: FAIL due to missing submit endpoint/validation.

**Step 3: Write minimal implementation**

- `InboxWriter` generates `<channel>-YYYY-MM-DD-<seq>.json`.
- Add `POST /api/submit-and-process`:
  - validate required fields
  - write inbox JSON file
  - run processor
  - return summary + entries JSON
- Return `422` JSON for bad input.

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/inbox_writer_test.rb`
Run: `ruby -Itest test/app_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/inbox_writer.rb app.rb lib/timy.rb test/inbox_writer_test.rb test/app_test.rb
git commit -m "feat: add submit and process api flow"
```

### Task 4: Add SPA Shell and Two-Panel UI

**Files:**
- Create: `views/index.erb`
- Create: `public/app.js`
- Create: `public/styles.css`
- Modify: `app.rb`
- Create: `test/ui_shell_test.rb`

**Step 1: Write the failing test**

```ruby
def test_root_renders_input_and_results_regions; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/ui_shell_test.rb`
Expected: FAIL because UI shell files/markers are missing.

**Step 3: Write minimal implementation**

- Build split layout:
  - left input form (`channel`, `sender`, `timestamp`, `message`)
  - right results container and follow-up section
- Add frontend fetch logic:
  - initial load from `/api/results`
  - submit to `/api/submit-and-process`
  - re-render right panel in place

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/ui_shell_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add views/index.erb public/app.js public/styles.css app.rb test/ui_shell_test.rb
git commit -m "feat: add browser simulation spa layout and client logic"
```

### Task 5: Harden Error Handling and End-to-End Behavior

**Files:**
- Modify: `app.rb`
- Modify: `public/app.js`
- Modify: `test/app_test.rb`
- Modify: `README.md`

**Step 1: Write the failing test**

```ruby
def test_submit_returns_500_json_when_processing_fails; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/app_test.rb`
Expected: FAIL because error contract not fully implemented.

**Step 3: Write minimal implementation**

- Ensure all API errors return JSON with `error` field.
- Frontend displays inline error state on the right panel.
- Update README with web run instructions.

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/app_test.rb`
Expected: PASS.

Then run full suite:

Run: `ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |f| require_relative f }'`
Expected: all PASS.

**Step 5: Commit**

```bash
git add app.rb public/app.js test/app_test.rb README.md
git commit -m "feat: finalize browser simulation flow and api error handling"
```
