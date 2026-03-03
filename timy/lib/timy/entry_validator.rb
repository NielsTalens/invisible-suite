# frozen_string_literal: true

module Timy
  class EntryValidator
    CONFIDENCE = %w[high medium low].freeze
    STATUS = %w[ok needs_clarification].freeze
    FALLBACK_QUESTION = "I could not fully parse this message. Could you clarify the project, date, and time spent?"

    def validate(source, raw_entry)
      normalized = raw_entry.is_a?(Hash) ? raw_entry : {}
      entry = base_entry(source).merge(normalized)
      if !raw_entry.nil? && !raw_entry.is_a?(Hash)
        entry["_recognizer_error"] = "Recognizer returned #{raw_entry.class}, expected Hash"
      end

      if valid_entry?(entry)
        if entry["status"] == "needs_clarification"
          entry["clarification_question"] = safe_question(entry["clarification_question"])
        else
          entry.delete("clarification_question")
        end
        return entry
      end

      fallback_entry(entry)
    end

    private

    def base_entry(source)
      {
        "source_file" => source["source_file"],
        "channel" => source["channel"],
        "sender" => source["sender"],
        "original_timestamp" => source["timestamp"]
      }
    end

    def valid_entry?(entry)
      required = %w[work_date project task_description duration_hours confidence status]
      return false unless required.all? { |k| entry.key?(k) }
      return false unless entry["duration_hours"].is_a?(Numeric)
      return false unless CONFIDENCE.include?(entry["confidence"])
      return false unless STATUS.include?(entry["status"])

      true
    end

    def fallback_entry(entry)
      result = {
        "source_file" => entry["source_file"],
        "channel" => entry["channel"],
        "sender" => entry["sender"],
        "original_timestamp" => entry["original_timestamp"],
        "work_date" => entry["work_date"],
        "project" => entry["project"] || "unknown",
        "task_description" => entry["task_description"] || "Unable to extract task details",
        "duration_hours" => entry["duration_hours"].is_a?(Numeric) ? entry["duration_hours"] : 0.0,
        "confidence" => "low",
        "status" => "needs_clarification",
        "clarification_question" => safe_question(entry["clarification_question"])
      }

      result["_recognizer_error"] = entry["_recognizer_error"] if entry.key?("_recognizer_error")
      result
    end

    def safe_question(value)
      return FALLBACK_QUESTION if value.nil? || value.strip.empty?

      value
    end
  end
end
