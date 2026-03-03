# frozen_string_literal: true

module Timy
  class CliReporter
    def initialize(io: $stdout)
      @io = io
    end

    def print(entries)
      ok_count = entries.count { |e| e["status"] == "ok" }
      clarify_count = entries.count { |e| e["status"] == "needs_clarification" }

      @io.puts "Total processed: #{entries.length}"
      @io.puts "ok: #{ok_count}"
      @io.puts "needs_clarification: #{clarify_count}"
      @io.puts
      @io.puts "Entries"
      entries.each do |entry|
        @io.puts "- #{entry["source_file"]} | #{entry["project"]} | #{entry["duration_hours"]}h | #{entry["status"]}"
      end

      questions = entries.select { |e| e["status"] == "needs_clarification" }
      return if questions.empty?

      @io.puts
      @io.puts "Follow-up Questions"
      questions.each do |entry|
        @io.puts "- #{entry["source_file"]}: #{entry["clarification_question"]}"
      end
    end
  end
end
