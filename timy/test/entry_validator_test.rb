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
  end

  def test_accepts_valid_entry_schema
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Alpha",
      "task_description" => "Planning",
      "duration_hours" => 1.5,
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new.validate(@source, entry)

    assert_equal "ok", result["status"]
    assert_equal 1.5, result["duration_hours"]
    assert_nil result["clarification_question"]
  end

  def test_marks_needs_clarification_when_schema_invalid
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Alpha",
      "task_description" => "Planning",
      "confidence" => "high",
      "status" => "ok"
    }

    result = Timy::EntryValidator.new.validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_match(/could you clarify/i, result["clarification_question"])
  end

  def test_requires_clarification_question_for_unclear_entries
    entry = {
      "work_date" => "2026-03-01",
      "project" => "Alpha",
      "task_description" => "Planning",
      "duration_hours" => 2,
      "confidence" => "low",
      "status" => "needs_clarification"
    }

    result = Timy::EntryValidator.new.validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    refute_nil result["clarification_question"]
  end

  def test_preserves_existing_clarification_question_and_recognizer_error_on_fallback
    entry = {
      "status" => "needs_clarification",
      "clarification_question" => "Which project should this be booked to?",
      "_recognizer_error" => "OpenAI request failed: 429"
    }

    result = Timy::EntryValidator.new.validate(@source, entry)

    assert_equal "needs_clarification", result["status"]
    assert_equal "Which project should this be booked to?", result["clarification_question"]
    assert_equal "OpenAI request failed: 429", result["_recognizer_error"]
  end

  def test_handles_non_hash_recognizer_payload_without_crashing
    result = Timy::EntryValidator.new.validate(@source, [])

    assert_equal "needs_clarification", result["status"]
    assert_equal "unknown", result["project"]
    assert_match(/clarify/i, result["clarification_question"])
  end
end
