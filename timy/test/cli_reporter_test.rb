require "test_helper"
require_relative "../lib/timy/cli_reporter"

class CliReporterTest < Minitest::Test
  def test_prints_summary_counts
    io = StringIO.new
    reporter = Timy::CliReporter.new(io: io)

    reporter.print([
      { "source_file" => "a.json", "project" => "Alpha", "duration_hours" => 2, "status" => "ok" },
      { "source_file" => "b.json", "project" => "Beta", "duration_hours" => 1, "status" => "needs_clarification", "clarification_question" => "What date?" }
    ])

    output = io.string
    assert_match(/Total processed: 2/, output)
    assert_match(/ok: 1/, output)
    assert_match(/needs_clarification: 1/, output)
  end

  def test_prints_follow_up_questions_section
    io = StringIO.new
    reporter = Timy::CliReporter.new(io: io)

    reporter.print([
      { "source_file" => "b.json", "project" => "Beta", "duration_hours" => 1, "status" => "needs_clarification", "clarification_question" => "What date?" }
    ])

    output = io.string
    assert_match(/Follow-up Questions/, output)
    assert_match(/b.json/, output)
    assert_match(/What date\?/, output)
  end
end
