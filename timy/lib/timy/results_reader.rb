# frozen_string_literal: true

require "yaml"

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
      parsed.is_a?(Array) ? parsed : []
    end
  end
end
