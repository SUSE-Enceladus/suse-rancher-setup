require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rancher_setup_login = rancher_setup_logins(:one)
  end

  test "should get index" do
    get rancher_setup_logins_url
    assert_response :success
  end

  test "should get new" do
    get new_rancher_setup_login_url
    assert_response :success
  end

  test "should create rancher_setup_login" do
    assert_difference("RancherSetupLogin.count") do
      post rancher_setup_logins_url, params: { rancher_setup_login: {  } }
    end

    assert_redirected_to rancher_setup_login_url(RancherSetupLogin.last)
  end

  test "should show rancher_setup_login" do
    get rancher_setup_login_url(@rancher_setup_login)
    assert_response :success
  end

  test "should get edit" do
    get edit_rancher_setup_login_url(@rancher_setup_login)
    assert_response :success
  end

  test "should update rancher_setup_login" do
    patch rancher_setup_login_url(@rancher_setup_login), params: { rancher_setup_login: {  } }
    assert_redirected_to rancher_setup_login_url(@rancher_setup_login)
  end

  test "should destroy rancher_setup_login" do
    assert_difference("RancherSetupLogin.count", -1) do
      delete rancher_setup_login_url(@rancher_setup_login)
    end

    assert_redirected_to rancher_setup_logins_url
  end
end
