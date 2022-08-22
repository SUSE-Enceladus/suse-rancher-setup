require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    mock_login
  end

  test "should get greeting" do

    mock_login
    get welcome_url
    assert_response :success
  end

  teardown do
    clear_login
  end
end
