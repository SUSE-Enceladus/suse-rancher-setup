require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rancher_setup_login = Login.load
  end

  test "should get index" do
    get login_index_url
    assert_response :success
  end

  test "should update login" do
    put login_url(id: 'update'), params: { login: { username: 'username', password: 'password' } }
    assert_redirected_to root_url
  end
end
