require "test_helper"
require_relative "../lib/timy/results_reader"

class ResultsReaderTest < Minitest::Test
  def test_reads_entries_and_builds_summary
    Dir.mktmpdir do |dir|
      data_file = File.join(dir, "timesheet_entries.yml")
      File.write(
        data_file,
        YAML.dump([
          { "project" => "A", "status" => "ok" },
          { "project" => "B", "status" => "needs_clarification" }
        ])
      )

      result = Timy::ResultsReader.new(data_dir: dir).read

      assert_equal 2, result["summary"]["processed"]
      assert_equal 1, result["summary"]["ok"]
      assert_equal 1, result["summary"]["needs_clarification"]
      assert_equal 2, result["entries"].length
    end
  end
end
