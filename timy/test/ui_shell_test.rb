require "test_helper"
require "rack/test"
require_relative "../app"

class UiShellTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TimyWeb
  end

  def test_root_renders_input_and_results_regions
    get "/", {}, { "HTTP_HOST" => "localhost" }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'id="input-panel"'
    assert_includes last_response.body, 'id="results-panel"'
    assert_includes last_response.body, 'name="channel"'
    refute_includes last_response.body, 'name="sender"'
    refute_includes last_response.body, 'name="timestamp_local"'
  end
end
