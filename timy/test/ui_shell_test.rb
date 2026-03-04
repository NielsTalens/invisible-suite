require "test_helper"
require "rack/test"
require_relative "../app"

class UiShellTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TimyWeb
  end

  def test_root_renders_channel_icon_selector_and_results_regions
    get "/", {}, { "HTTP_HOST" => "localhost" }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'id="input-panel"'
    assert_includes last_response.body, 'id="results-panel"'
    assert_includes last_response.body, 'id="toggle-results"'
    assert_includes last_response.body, 'id="results-content"'
    assert_includes last_response.body, 'id="channel-mail"'
    assert_includes last_response.body, '✉️'
    assert_includes last_response.body, '💬'
    assert_includes last_response.body, '🟢'
    refute_includes last_response.body, 'name="sender"'
    refute_includes last_response.body, 'name="timestamp_local"'
    assert_includes last_response.body, 'id="composer-shell"'
    assert_includes last_response.body, 'class="composer-shell composer-mail"'
    assert_includes last_response.body, 'id="composer-meta-mail"'
    assert_includes last_response.body, 'id="composer-meta-sms"'
    assert_includes last_response.body, 'id="composer-meta-whatsapp"'
    assert_includes last_response.body, 'id="status-spinner"'
    assert_includes last_response.body, 'id="status-elapsed"'
    assert_includes last_response.body, 'id="latest-confirmation"'
  end
end
