# Message Ingestion and Structuring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Ruby CLI that reads JSON message files, structures them with OpenAI, stores entries in YAML, and prints results including clarification questions.

**Architecture:** A small layered Ruby app with separate components for input loading, OpenAI recognition, schema validation, YAML persistence, and CLI reporting. The command entrypoint orchestrates the pipeline and handles failures with deterministic fallback records.

**Tech Stack:** Ruby, Minitest, dotenv, ruby-openai, YAML/JSON, rake

---

### Task 1: Scaffold Project Runtime

**Files:**
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `.env.example`
- Create: `bin/process_messages`
- Create: `lib/timy.rb`
- Create: `test/test_helper.rb`

**Step 1: Write the failing test**

```ruby
# test/test_helper_test.rb
require "test_helper"

class TestHelperTest < Minitest::Test
  def test_loads_test_runtime
    assert defined?(Minitest)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/test_helper_test.rb`
Expected: FAIL because `test_helper.rb` is missing.

**Step 3: Write minimal implementation**

```ruby
# test/test_helper.rb
require "minitest/autorun"
require_relative "../lib/timy"
```

Also add minimal `Gemfile`, `Rakefile`, executable `bin/process_messages`, and `.env.example` with `OPENAI_API_KEY=`.

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/test_helper_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add Gemfile Rakefile .env.example bin/process_messages lib/timy.rb test/test_helper.rb test/test_helper_test.rb
git commit -m "chore: scaffold ruby cli runtime"
```

### Task 2: Input Loader for JSON Inbox

**Files:**
- Create: `lib/timy/input_loader.rb`
- Test: `test/input_loader_test.rb`

**Step 1: Write the failing test**

```ruby
def test_loads_valid_messages_sorted_by_timestamp
  # create two temp json files with required keys and different timestamps
  # expect returned messages sorted ascending
end

def test_rejects_invalid_message_shape
  # missing required key should produce error entry
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/input_loader_test.rb`
Expected: FAIL with `LoadError`/missing class.

**Step 3: Write minimal implementation**

```ruby
module Timy
  class InputLoader
    REQUIRED_KEYS = %w[channel sender timestamp message].freeze
    # load messages from inbox/*.json and validate keys
  end
end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/input_loader_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/input_loader.rb test/input_loader_test.rb
git commit -m "feat: add json inbox input loader"
```

### Task 3: Output Schema Validator and Fallback Logic

**Files:**
- Create: `lib/timy/entry_validator.rb`
- Test: `test/entry_validator_test.rb`

**Step 1: Write the failing test**

```ruby
def test_accepts_valid_entry_schema; end
def test_marks_needs_clarification_when_schema_invalid; end
def test_requires_clarification_question_for_unclear_entries; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/entry_validator_test.rb`
Expected: FAIL because validator class does not exist.

**Step 3: Write minimal implementation**

```ruby
# validate required fields, enums, numeric duration, and fallback question
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/entry_validator_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/entry_validator.rb test/entry_validator_test.rb
git commit -m "feat: add entry schema validation and fallback handling"
```

### Task 4: OpenAI Recognizer Adapter

**Files:**
- Create: `lib/timy/openai_recognizer.rb`
- Test: `test/openai_recognizer_test.rb`

**Step 1: Write the failing test**

```ruby
def test_builds_request_and_returns_parsed_json; end
def test_returns_fallback_payload_on_invalid_json_response; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/openai_recognizer_test.rb`
Expected: FAIL due to missing recognizer.

**Step 3: Write minimal implementation**

```ruby
# uses OpenAI::Client, sends strict schema instructions, parses JSON safely
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/openai_recognizer_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/openai_recognizer.rb test/openai_recognizer_test.rb
git commit -m "feat: add openai recognizer adapter"
```

### Task 5: YAML Repository for Entries and Logs

**Files:**
- Create: `lib/timy/yaml_repository.rb`
- Test: `test/yaml_repository_test.rb`

**Step 1: Write the failing test**

```ruby
def test_appends_entries_to_timesheet_yaml; end
def test_appends_run_log_to_processing_log_yaml; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/yaml_repository_test.rb`
Expected: FAIL due to missing repository class.

**Step 3: Write minimal implementation**

```ruby
# ensure data files exist, load existing arrays, append, then write back
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/yaml_repository_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/yaml_repository.rb test/yaml_repository_test.rb
git commit -m "feat: add yaml repository for entries and processing logs"
```

### Task 6: CLI Reporter

**Files:**
- Create: `lib/timy/cli_reporter.rb`
- Test: `test/cli_reporter_test.rb`

**Step 1: Write the failing test**

```ruby
def test_prints_summary_counts; end
def test_prints_follow_up_questions_section; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/cli_reporter_test.rb`
Expected: FAIL because reporter class is missing.

**Step 3: Write minimal implementation**

```ruby
# render summary, row list, and clarification questions to IO
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/cli_reporter_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/cli_reporter.rb test/cli_reporter_test.rb
git commit -m "feat: add cli reporting output"
```

### Task 7: Orchestration Command

**Files:**
- Create: `lib/timy/processor.rb`
- Modify: `lib/timy.rb`
- Modify: `bin/process_messages`
- Test: `test/processor_integration_test.rb`

**Step 1: Write the failing test**

```ruby
def test_processes_inbox_and_persists_entries_with_reporting; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/processor_integration_test.rb`
Expected: FAIL with missing processor.

**Step 3: Write minimal implementation**

```ruby
# wire loader -> recognizer -> validator -> repository -> reporter
```

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/processor_integration_test.rb`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/timy/processor.rb lib/timy.rb bin/process_messages test/processor_integration_test.rb
git commit -m "feat: wire end-to-end message processing pipeline"
```

### Task 8: Verify Full Test Suite and Usage Docs

**Files:**
- Create: `README.md`
- Modify: `.env.example`

**Step 1: Write the failing test**

```ruby
def test_bin_fails_fast_when_api_key_missing; end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Itest test/processor_integration_test.rb`
Expected: FAIL because missing key check is not implemented.

**Step 3: Write minimal implementation**

```ruby
# add explicit OPENAI_API_KEY check in bin/process_messages
```

Add `README.md` usage:
- install gems
- create `.env`
- place JSON files in `inbox/`
- run `bin/process_messages`

**Step 4: Run test to verify it passes**

Run: `ruby -Itest test/processor_integration_test.rb`
Expected: PASS.

Then run full suite:

Run: `ruby -Itest -e 'Dir[\"test/**/*_test.rb\"].sort.each { |f| require_relative f }'`
Expected: all PASS.

**Step 5: Commit**

```bash
git add README.md .env.example bin/process_messages test/processor_integration_test.rb
git commit -m "docs: add setup and harden api key validation"
```
