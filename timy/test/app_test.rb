require "test_helper"
require "rack/test"
require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TimyWeb
  end

  def test_root_route_returns_success
    get "/", {}, { "HTTP_HOST" => "localhost" }
    assert_equal 200, last_response.status
  end

  def test_api_results_returns_summary_and_entries
    get "/api/results", {}, { "HTTP_HOST" => "localhost" }

    assert_equal 200, last_response.status
    json = JSON.parse(last_response.body)
    assert json.key?("summary")
    assert json.key?("entries")
  end

  def test_submit_and_process_rejects_invalid_payload
    post "/api/submit-and-process", { "channel" => "fax", "lines" => ["test"] }.to_json, { "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json" }

    assert_equal 422, last_response.status
    json = JSON.parse(last_response.body)
    assert json.key?("error")
  end

  def test_submit_and_process_writes_inbox_file_and_returns_results
    Dir.mktmpdir do |dir|
      inbox = File.join(dir, "inbox")
      data = File.join(dir, "data")
      FileUtils.mkdir_p(inbox)
      FileUtils.mkdir_p(data)

      TimyWeb.set :inbox_dir, inbox
      TimyWeb.set :data_dir, data
      TimyWeb.set :recognizer_factory, -> { FakeRecognizer.new }

      payload = {
        "channel" => "mail",
        "lines" => ["Worked 2h on Alpha", "30m sprint planning"]
      }

      post "/api/submit-and-process", payload.to_json, { "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json" }

      assert_equal 200, last_response.status
      files = Dir.glob(File.join(inbox, "*.json"))
      assert_equal 2, files.length
      first = JSON.parse(File.read(files.first))
      assert_equal "niels@example.com", first["sender"]
      assert_equal "mail", first["channel"]
      refute_nil first["timestamp"]

      body = JSON.parse(last_response.body)
      assert_equal 2, body.dig("summary", "processed")
      assert_equal 2, body.fetch("entries").length
    end
  ensure
    TimyWeb.set :inbox_dir, "inbox"
    TimyWeb.set :data_dir, "data"
    TimyWeb.set :recognizer_factory, nil
  end

  def test_submit_returns_500_json_when_processing_fails
    TimyWeb.set :recognizer_factory, -> { raise "boom" }

    payload = {
      "channel" => "mail",
      "lines" => ["Worked 2h on Alpha"]
    }
    post "/api/submit-and-process", payload.to_json, { "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json" }

    assert_equal 500, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal "boom", json["error"]
  ensure
    TimyWeb.set :recognizer_factory, nil
  end

  def test_submit_rejects_empty_lines
    payload = {
      "channel" => "mail",
      "lines" => ["   ", ""]
    }
    post "/api/submit-and-process", payload.to_json, { "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json" }

    assert_equal 422, last_response.status
    json = JSON.parse(last_response.body)
    assert_match(/lines/i, json["error"])
  end

  class FakeRecognizer
    def recognize(_message)
      {
        "work_date" => "2026-03-04",
        "project" => "Alpha",
        "task_description" => "Implementation",
        "duration_hours" => 2.0,
        "confidence" => "high",
        "status" => "ok"
      }
    end
  end
end
