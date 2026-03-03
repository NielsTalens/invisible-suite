# frozen_string_literal: true

require "json"
require "time"

module Timy
  class InputLoader
    REQUIRED_KEYS = %w[channel sender timestamp message].freeze

    def initialize(inbox_dir)
      @inbox_dir = inbox_dir
    end

    def load
      valid = []
      errors = []

      Dir.glob(File.join(@inbox_dir, "*.json")).sort.each do |path|
        source_file = File.basename(path)
        begin
          payload = JSON.parse(File.read(path))
          missing = REQUIRED_KEYS.reject { |k| payload.key?(k) }
          if missing.any?
            errors << { source_file: source_file, error: "missing required keys: #{missing.join(', ')}" }
            next
          end

          valid << payload.merge("source_file" => source_file)
        rescue JSON::ParserError => e
          errors << { source_file: source_file, error: "invalid JSON: #{e.message}" }
        end
      end

      valid.sort_by! { |msg| Time.parse(msg.fetch("timestamp")) }
      { valid: valid, errors: errors }
    end
  end
end
