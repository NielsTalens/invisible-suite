# frozen_string_literal: true

require "yaml"
require "time"

module Timy
  class ResultsReader
    def initialize(data_dir: "data")
      @data_dir = data_dir
    end

    def read
      entries = read_entries
      {
        "summary" => {
          "processed" => entries.length,
          "ok" => entries.count { |e| e["status"] == "ok" },
          "needs_clarification" => entries.count { |e| e["status"] == "needs_clarification" }
        },
        "entries" => entries
      }
    end

    private

    def read_entries
      path = File.join(@data_dir, "timesheet_entries.yml")
      return [] unless File.exist?(path)

      parsed = YAML.load_file(path)
      return [] unless parsed.is_a?(Array)

      parsed.sort_by do |entry|
        [sort_timestamp(entry["original_timestamp"]), entry["source_file"].to_s]
      end.reverse
    end

    def sort_timestamp(value)
      Time.parse(value.to_s).to_i
    rescue ArgumentError
      0
    end
  end
end
