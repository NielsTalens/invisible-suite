require "test_helper"
require_relative "../lib/timy/input_loader"
require_relative "../lib/timy/entry_validator"
require_relative "../lib/timy/yaml_repository"
require_relative "../lib/timy/cli_reporter"
require_relative "../lib/timy/processor"

class ProcessorIntegrationTest < Minitest::Test
  class FakeRecognizer
    def recognize(message)
      if message["message"].include?("unknown")
        { "work_date" => "2026-03-01", "project" => "Alpha", "task_description" => "Unknown", "duration_hours" => 0.0, "confidence" => "low", "status" => "needs_clarification" }
      else
        { "work_date" => "2026-03-01", "project" => "Alpha", "task_description" => "Coding", "duration_hours" => 2.0, "confidence" => "high", "status" => "ok" }
      end
    end
  end

  def test_processes_inbox_and_persists_entries_with_reporting
    Dir.mktmpdir do |dir|
      inbox = File.join(dir, "inbox")
      data = File.join(dir, "data")
      FileUtils.mkdir_p(inbox)

      File.write(File.join(inbox, "m1.json"), JSON.dump({"channel" => "email", "sender" => "nelis", "timestamp" => "2026-03-01T09:00:00Z", "message" => "spent 2h coding"}))
      File.write(File.join(inbox, "m2.json"), JSON.dump({"channel" => "sms", "sender" => "nelis", "timestamp" => "2026-03-01T10:00:00Z", "message" => "unknown"}))

      io = StringIO.new
      processor = Timy::Processor.new(
        loader: Timy::InputLoader.new(inbox),
        recognizer: FakeRecognizer.new,
        validator: Timy::EntryValidator.new,
        repository: Timy::YamlRepository.new(data_dir: data),
        reporter: Timy::CliReporter.new(io: io)
      )

      processor.run

      entries = YAML.load_file(File.join(data, "timesheet_entries.yml"))
      assert_equal 2, entries.length
      assert_match(/Total processed: 2/, io.string)
      assert_match(/Follow-up Questions/, io.string)
    end
  end

  def test_clears_existing_timesheet_entries_before_new_run
    Dir.mktmpdir do |dir|
      inbox = File.join(dir, "inbox")
      data = File.join(dir, "data")
      FileUtils.mkdir_p(inbox)
      FileUtils.mkdir_p(data)

      File.write(
        File.join(data, "timesheet_entries.yml"),
        YAML.dump([{ "project" => "OldProject", "status" => "ok" }])
      )
      File.write(File.join(inbox, "m1.json"), JSON.dump({ "channel" => "email", "sender" => "nelis", "timestamp" => "2026-03-01T09:00:00Z", "message" => "spent 2h coding" }))

      io = StringIO.new
      processor = Timy::Processor.new(
        loader: Timy::InputLoader.new(inbox),
        recognizer: FakeRecognizer.new,
        validator: Timy::EntryValidator.new,
        repository: Timy::YamlRepository.new(data_dir: data),
        reporter: Timy::CliReporter.new(io: io)
      )

      processor.run

      entries = YAML.load_file(File.join(data, "timesheet_entries.yml"))
      assert_equal 1, entries.length
      assert_equal "Alpha", entries.first["project"]
    end
  end

  def test_bin_fails_fast_when_api_key_missing
    output = `OPENAI_API_KEY= ruby bin/process_messages 2>&1`
    assert_match(/OPENAI_API_KEY is required/, output)
  end
end
