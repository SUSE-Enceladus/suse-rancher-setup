require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    mock_login
  end

  test "should get greeting" do
    get welcome_url
    assert_response :success
  end
end
