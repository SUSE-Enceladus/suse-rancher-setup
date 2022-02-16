require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get greeting" do
    get welcome_greeting_url
    assert_response :success
  end
end
