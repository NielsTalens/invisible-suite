require "test_helper"
require_relative "../lib/timy/yaml_repository"

class YamlRepositoryTest < Minitest::Test
  def test_appends_entries_to_timesheet_yaml
    Dir.mktmpdir do |dir|
      repo = Timy::YamlRepository.new(data_dir: dir)

      repo.append_entry({ "project" => "Alpha", "status" => "ok" })
      repo.append_entry({ "project" => "Beta", "status" => "needs_clarification" })

      data = YAML.load_file(File.join(dir, "timesheet_entries.yml"))
      assert_equal 2, data.length
      assert_equal "Beta", data.last["project"]
    end
  end

  def test_appends_run_log_to_processing_log_yaml
    Dir.mktmpdir do |dir|
      repo = Timy::YamlRepository.new(data_dir: dir)

      repo.append_log({ "processed" => 2, "errors" => 1 })

      data = YAML.load_file(File.join(dir, "processing_log.yml"))
      assert_equal 1, data.length
      assert_equal 2, data.first["processed"]
    end
  end
end
