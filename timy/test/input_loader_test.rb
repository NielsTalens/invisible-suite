require "test_helper"
require_relative "../lib/timy/input_loader"

class InputLoaderTest < Minitest::Test
  def test_loads_valid_messages_sorted_by_timestamp
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "b.json"), JSON.dump({"channel" => "sms", "sender" => "a", "timestamp" => "2026-03-02T10:00:00Z", "message" => "Worked 2h on Alpha"}))
      File.write(File.join(dir, "a.json"), JSON.dump({"channel" => "email", "sender" => "b", "timestamp" => "2026-03-01T09:00:00Z", "message" => "Did 1h planning"}))

      result = Timy::InputLoader.new(dir).load

      assert_equal 2, result[:valid].length
      assert_equal "a.json", result[:valid][0]["source_file"]
      assert_equal "b.json", result[:valid][1]["source_file"]
      assert_equal [], result[:errors]
    end
  end

  def test_rejects_invalid_message_shape
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "bad.json"), JSON.dump({"channel" => "email", "message" => "missing keys"}))

      result = Timy::InputLoader.new(dir).load

      assert_equal 0, result[:valid].length
      assert_equal 1, result[:errors].length
      assert_match(/missing required keys/i, result[:errors][0][:error])
      assert_equal "bad.json", result[:errors][0][:source_file]
    end
  end
end
