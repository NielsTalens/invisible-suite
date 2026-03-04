require "test_helper"
require "rack/test"
require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TimyWeb
  end

  def test_root_route_returns_success
    get "/"
    assert_equal 200, last_response.status
  end
end
