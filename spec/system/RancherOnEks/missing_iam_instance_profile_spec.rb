require 'web_helper'

return unless defined?(RancherOnEks::Engine)

RSpec::Steps.steps('RancherOnEks: missing IAM Instance Profile', type: :system) do
  before(:all) do
    driven_by(:rack_test)
  end

  before(:example) do
    allow_any_instance_of(AWS::Metadata).to receive(:instance_profile_arn).and_return(nil)
    cheetah_vcr()
  end

  it 'shows an error message' do
    # log in first
    visit(main_app.root_path)
    expect(page).to have_text(t('login.content'))
    fill_in('user_username', with: 'username')
    fill_in('user_password', with: 'password')
    click_on(t('actions.login'))

    visit(aws.permissions_path)
    expect(find('.alert-danger')).to have_content(t('flash.missing_instance_profile'))
    expect(page).to have_content(t('engines.aws.permissions.missing_instance_profile'))
  end
end
