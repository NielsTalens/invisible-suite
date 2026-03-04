require "test_helper"
require_relative "../lib/timy/entry_validator"

class EntryValidatorTest < Minitest::Test
  def setup
    @source = {
      "source_file" => "msg1.json",
      "channel" => "email",
      "sender" => "nelis",
      "timestamp" => "2026-03-01T09:00:00Z"
    }
    @catalog = {
      "projects" => ["Gareth", "Xero", "B&B"],
      "tasks" => {
        "programming" => ["coding", "engineering", "development", "developing"],
        "design" => ["creating graphics", "graphic design", "graphics"],
        "meetings" => ["meeting", "standup", "planning"],
        "administrative" => ["admin", "administration", "paperwork"]
      }
    }
  end

  def test_accepts_valid_entry_schema
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Gareth",
      "task_description" => "programming",
      "duration_hours" => 1.5,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "ok", result["status"]
    assert_equal 1.5, result["duration_hours"]
    assert_nil result["clarification_question"]
  end

  def test_marks_needs_clarification_when_schema_invalid
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Gareth",
      "task_description" => "programming",
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_match(/could you clarify/i, result["clarification_question"])
  end

  def test_requires_clarification_question_for_unclear_entries
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Gareth",
      "task_description" => "programming",
      "duration_hours" => 2,
      "confidence" => "low",
      "status" => "needs_clarification"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    refute_nil result["clarification_question"]
  end

  def test_preserves_existing_clarification_question_and_recognizer_error_on_fallback
    entry = {
      "status" => "needs_clarification",
      "clarification_question" => "Which project should this be booked to?",
      "_recognizer_error" => "OpenAI request failed: 429"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_equal "Which project should this be booked to?", result["clarification_question"]
    assert_equal "OpenAI request failed: 429", result["_recognizer_error"]
  end

  def test_handles_non_hash_recognizer_payload_without_crashing
    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, [])

    assert_equal "needs_clarification", result["status"]
    assert_equal "unknown", result["project"]
    assert_match(/clarify/i, result["clarification_question"])
  end

  def test_auto_corrects_project_typo_and_task_synonym
    entry = {
      "work_date" => "2026-03-01",
      "project" => "grareth",
      "task_description" => "engineering",
      "duration_hours" => 2.5,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "ok", result["status"]
    assert_equal "Gareth", result["project"]
    assert_equal "programming", result["task_description"]
  end

  def test_auto_corrects_project_brand_like_typo
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Xerox",
      "task_description" => "programming",
      "duration_hours" => 1.0,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "ok", result["status"]
    assert_equal "Xero", result["project"]
  end

  def test_marks_needs_clarification_when_project_is_unrecognized
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Moonshot",
      "task_description" => "programming",
      "duration_hours" => 1.0,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_match(/Gareth, Xero, B&B/, result["clarification_question"])
  end

  def test_marks_needs_clarification_when_task_is_unrecognized
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Gareth",
      "task_description" => "deep thinking",
      "duration_hours" => 1.0,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new(catalog: @catalog).validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_match(/programming, design, meetings, administrative/, result["clarification_question"])
  end
end
