require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rancher_setup_login = login(:one)
  end

  test "should get index" do
    get logins_url
    assert_response :success
  end

  test "should get new" do
    get new_login_url
    assert_response :success
  end

  test "should create rancher_setup_login" do
    assert_difference("Login.count") do
      post login_url, params: { login: {  } }
    end

    assert_redirected_to login_url(Login.last)
  end

  test "should show login" do
    get login_url(@rancher_setup_login)
    assert_response :success
  end

  test "should get edit" do
    get edit_login_url(@rancher_setup_login)
    assert_response :success
  end

  test "should update login" do
    patch login_url(@rancher_setup_login), params: { rancher_setup_login: {  } }
    assert_redirected_to login_url(@rancher_setup_login)
  end
end
