require "test_helper"
require_relative "../lib/timy/openai_recognizer"

class OpenAiRecognizerTest < Minitest::Test
  class FakeClient
    attr_reader :last_request

    def initialize(response)
      @response = response
    end

    def responses
      self
    end

    def create(parameters:)
      @last_request = parameters
      @response
    end
  end

  def test_builds_request_and_returns_parsed_json
    client = FakeClient.new(
      "output" => [
        {
          "content" => [
            {
              "text" => '{"work_date":"2026-03-01","project":"Alpha","task_description":"Dev","duration_hours":2,"confidence":"high","status":"ok"}'
            }
          ]
        }
      ]
    )
    recognizer = Timy::OpenAiRecognizer.new(client: client, model: "gpt-4.1-mini")

    result = recognizer.recognize(
      "channel" => "email",
      "sender" => "nelis",
      "timestamp" => "2026-03-01T09:00:00Z",
      "message" => "Spent 2h coding"
    )

    assert_equal "Alpha", result["project"]
    assert_equal "gpt-4.1-mini", client.last_request[:model]
  end

  def test_parses_json_from_output_text_field
    client = FakeClient.new(
      "output_text" => '{"work_date":"2026-03-02","project":"Beta","task_description":"Support","duration_hours":1,"confidence":"medium","status":"ok"}'
    )
    recognizer = Timy::OpenAiRecognizer.new(client: client, model: "gpt-4.1-mini")

    result = recognizer.recognize(
      "channel" => "email",
      "sender" => "nelis",
      "timestamp" => "2026-03-01T09:00:00Z",
      "message" => "Spent 1h support"
    )

    assert_equal "Beta", result["project"]
  end

  def test_parses_json_wrapped_in_markdown_fences
    client = FakeClient.new(
      "output_text" => "```json\n{\"work_date\":\"2026-03-03\",\"project\":\"Gamma\",\"task_description\":\"Planning\",\"duration_hours\":0.5,\"confidence\":\"high\",\"status\":\"ok\"}\n```"
    )
    recognizer = Timy::OpenAiRecognizer.new(client: client, model: "gpt-4.1-mini")

    result = recognizer.recognize(
      "channel" => "email",
      "sender" => "nelis",
      "timestamp" => "2026-03-01T09:00:00Z",
      "message" => "Spent 30m planning"
    )

    assert_equal "Gamma", result["project"]
  end

  def test_returns_fallback_payload_with_error_on_invalid_json_response
    client = FakeClient.new("output_text" => "not-json")
    recognizer = Timy::OpenAiRecognizer.new(client: client, model: "gpt-4.1-mini")

    result = recognizer.recognize(
      "channel" => "email",
      "sender" => "nelis",
      "timestamp" => "2026-03-01T09:00:00Z",
      "message" => "Spent 2h coding"
    )

    assert_equal "needs_clarification", result["status"]
    assert_match(/clarify/i, result["clarification_question"])
    refute_nil result["_recognizer_error"]
    assert_equal "unknown", result["project"]
    assert_equal 0.0, result["duration_hours"]
  end

  def test_normalizes_array_json_response_to_first_hash
    client = FakeClient.new(
      "output_text" => '[{"work_date":"2026-03-04","project":"Alpha","task_description":"Dev","duration_hours":2,"confidence":"high","status":"ok"}]'
    )
    recognizer = Timy::OpenAiRecognizer.new(client: client, model: "gpt-4.1-mini")

    result = recognizer.recognize(
      "channel" => "mail",
      "sender" => "niels@example.com",
      "timestamp" => "2026-03-04T09:00:00Z",
      "message" => "Worked 2h"
    )

    assert_equal "Alpha", result["project"]
    assert_equal "ok", result["status"]
  end
end
