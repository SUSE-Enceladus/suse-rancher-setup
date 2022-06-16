require "application_system_test_case"

class RancherSetupLoginsTest < ApplicationSystemTestCase
  setup do
    @rancher_setup_login = rancher_setup_logins(:one)
  end

  test "visiting the index" do
    visit rancher_setup_logins_url
    assert_selector "h1", text: "Rancher setup logins"
  end

  test "should create rancher setup login" do
    visit rancher_setup_logins_url
    click_on "New rancher setup login"

    click_on "Create Rancher setup login"

    assert_text "Rancher setup login was successfully created"
    click_on "Back"
  end

  test "should update Rancher setup login" do
    visit rancher_setup_login_url(@rancher_setup_login)
    click_on "Edit this rancher setup login", match: :first

    click_on "Update Rancher setup login"

    assert_text "Rancher setup login was successfully updated"
    click_on "Back"
  end

  test "should destroy Rancher setup login" do
    visit rancher_setup_login_url(@rancher_setup_login)
    click_on "Destroy this rancher setup login", match: :first

    assert_text "Rancher setup login was successfully destroyed"
  end
end
