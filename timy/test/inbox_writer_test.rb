require "test_helper"
require_relative "../lib/timy/inbox_writer"

class InboxWriterTest < Minitest::Test
  def test_writes_file_with_expected_name_pattern
    Dir.mktmpdir do |dir|
      writer = Timy::InboxWriter.new(inbox_dir: dir)
      path = writer.write(
        "channel" => "email",
        "sender" => "nelis@example.com",
        "timestamp" => "2026-03-04T09:00:00Z",
        "message" => "Worked 2h"
      )

      assert_match(%r{email-2026-03-04-001\.json$}, path)
      assert File.exist?(path)
      payload = JSON.parse(File.read(path))
      assert_equal "Worked 2h", payload["message"]
    end
  end
end
