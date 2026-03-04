# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Timy
  class OpenAiRecognizer
    FALLBACK = {
      "work_date" => nil,
      "project" => "unknown",
      "task_description" => "Unable to extract task details",
      "duration_hours" => 0.0,
      "confidence" => "low",
      "status" => "needs_clarification",
      "clarification_question" => "I could not confidently extract your timesheet entry. Could you clarify date, project, and hours?"
    }.freeze

    def initialize(client: nil, model: ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini"), api_key: ENV["OPENAI_API_KEY"])
      @client = client || HttpClient.new(api_key)
      @model = model
    end

    def recognize(message)
      response = @client.responses.create(parameters: request_payload(message, @model))
      text = extract_text(response)
      parsed = JSON.parse(normalize_json_text(text))
      normalize_parsed_payload(parsed)
    rescue StandardError => e
      FALLBACK.merge("_recognizer_error" => e.message)
    end

    private

    def request_payload(message, model)
      {
        model: model,
        input: [
          {
            role: "system",
            content: "Return ONLY JSON with keys: work_date, project, task_description, duration_hours, confidence(high|medium|low), status(ok|needs_clarification), clarification_question(optional)."
          },
          {
            role: "user",
            content: JSON.dump(message)
          }
        ]
      }
    end

    def extract_text(response)
      return response["output_text"] if response.is_a?(Hash) && response["output_text"].is_a?(String)

      output = response.fetch("output")
      first = output.first
      content = first.fetch("content")
      text_part = content.find { |part| part.is_a?(Hash) && part["text"].is_a?(String) }
      raise "OpenAI response text not found" if text_part.nil?

      text_part.fetch("text")
    end

    def normalize_json_text(text)
      stripped = text.to_s.strip
      if stripped.start_with?("```")
        stripped = stripped.gsub(/\A```[a-zA-Z]*\n?/, "").gsub(/\n?```\z/, "").strip
      end
      stripped
    end

    def normalize_parsed_payload(parsed)
      return parsed if parsed.is_a?(Hash)
      return parsed.find { |item| item.is_a?(Hash) } if parsed.is_a?(Array)

      raise "OpenAI parsed payload is not an object"
    end

    class HttpClient
      def initialize(api_key)
        @api_key = api_key
      end

      def responses
        self
      end

      def create(parameters:)
        raise "OPENAI_API_KEY missing" if @api_key.nil? || @api_key.empty?

        uri = URI("https://api.openai.com/v1/responses")
        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"] = "application/json"
        req.body = JSON.dump(parameters)

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
        raise "OpenAI request failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body)
      end
    end
  end
end
