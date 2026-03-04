require "test_helper"
require_relative "../lib/timy/results_reader"

class ResultsReaderTest < Minitest::Test
  def test_reads_entries_sorted_newest_first
    Dir.mktmpdir do |dir|
      data_file = File.join(dir, "timesheet_entries.yml")
      File.write(
        data_file,
        YAML.dump([
          { "source_file" => "mail-2026-03-04-001.json", "original_timestamp" => "2026-03-04T09:00:00Z", "status" => "ok" },
          { "source_file" => "mail-2026-03-04-003.json", "original_timestamp" => "2026-03-04T11:00:00Z", "status" => "needs_clarification" },
          { "source_file" => "mail-2026-03-04-002.json", "original_timestamp" => "2026-03-04T11:00:00Z", "status" => "ok" }
        ])
      )

      result = Timy::ResultsReader.new(data_dir: dir).read

      entries = result.fetch("entries")
      assert_equal "mail-2026-03-04-003.json", entries[0]["source_file"]
      assert_equal "mail-2026-03-04-002.json", entries[1]["source_file"]
      assert_equal "mail-2026-03-04-001.json", entries[2]["source_file"]
    end
  end
end
