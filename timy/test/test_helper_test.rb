require "test_helper"

class TestHelperTest < Minitest::Test
  def test_loads_test_runtime
    assert defined?(Minitest)
  end
end
