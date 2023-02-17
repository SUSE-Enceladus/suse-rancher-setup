require 'web_helper'

return unless defined?(RancherOnAks::Engine)

RSpec::Steps.steps('RancherOnAks: small cluster', type: :system) do
  let(:test_region) { 'westus2' }
  let(:test_shirt_size) { 'small' }
  let(:test_fqdn) { 'rancher-setup-test.azure.bear454.com' }
  let(:test_app_id) { 'fd728d26-aaff-4d13-8da0-30a6a37d1c4b' }
  # Actual password required for re-recording
  let(:test_password) { ENV['PASSWORD'] || 'password' }
  let(:test_tenant) { '0ccfaef4-daa6-4918-8b2a-b9ca95f4a88f' }
  let(:test_tls_source) { 'rancher' }

  before(:all) do
    driven_by(:rack_test)
    # driven_by(:selenium)
  end

  before(:example) do
    if ENV['RERECORD']
      # Send argument cheetah_vcr(force_recording: true) to force a new recording
      cheetah_vcr(context: 'rancher_on_aks-happy_path', force_recording: true)
   else
      # The 4-digit random number needs to match the last recording, and this stub
      # should be disabled when re-recording. Reset with value from:
      #
      # grep 'TAG RANDOM ID' log/test.log
      allow_any_instance_of(RancherOnAks::Deployment).to receive(:random_num).and_return(2014)

      cheetah_vcr(context: 'rancher_on_aks-happy_path')
    end
    allow_any_instance_of(RancherOnAks::Fqdn).to receive(:dns_record_exist?).and_return(false)
  end

  it 'prompts for login before the welcome page' do
    visit(main_app.root_path)
    expect(page).to have_text(t('login.content'))
    fill_in('user_username', with: 'username')
    fill_in('user_password', with: 'password')
    click_on(t('actions.login'))
    expect(page).to have_current_path(main_app.welcome_path)
  end

  it 'greets on the welcome page' do
    visit(main_app.welcome_path)
    expect(page).to have_text(t('workflow.rancher_on_aks.product_brand.title'))
    expect(page).to have_text(t('workflow.rancher_on_aks.greeting.content'))
  end

  it 'presents the azure auth after welcome' do
    visit(main_app.welcome_path)
    click_on(t('actions.next'))
    expect(page).to have_current_path(azure.edit_login_path)
    expect(page).to have_content(t('engines.azure.login.title'))
  end

  it 'presents the region page after azure auth' do
    expect(page).to have_current_path(azure.edit_login_path)
    fill_in('credential_app_id', with: test_app_id)
    fill_in('credential_password', with: test_password )
    fill_in('credential_tenant', with: test_tenant)
    click_on(t('actions.next'))
    expect(page).to have_current_path(azure.edit_region_path)
    expect(find('.alert-success')).to have_content(t('engines.azure.login.success', service_principal: test_app_id))
    expect(page).to have_content(t('engines.azure.region.title'))
    expect(page).to have_content(t('engines.azure.region.form_caption'))
  end

  it 'sets a region and presents the cluster sizing page' do
    visit(azure.edit_region_path)
    select_value(test_region, from: 'region_value')
    click_on(t('actions.next'))
    expect(page).to have_current_path(shirt_size.edit_size_path)
    expect(find('.alert-success')).to have_content(t('engines.azure.region.using', region: test_region))
  end

  it 'sets the cluster size and presents the FQDN page' do
    visit(shirt_size.edit_size_path)
    choose(t("engines.shirt_size.sizes.labels.#{test_shirt_size}"))
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_aks.edit_fqdn_path)
    expect(find('.alert-success')).to have_content(t('engines.shirt_size.sizes.using', size: test_shirt_size))
  end

  it 'sets the FQDN and presents the security page' do
    visit(rancher_on_aks.edit_fqdn_path)
    fill_in('fqdn_value', with: test_fqdn)
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_aks.edit_security_path)
    expect(find('.alert-success')).to have_content(t('flash.using_fqdn', fqdn: test_fqdn))
  end

  it 'selects a certificate source and presents the pre-flight checks page' do
    visit(rancher_on_aks.edit_security_path)
    within 'select#tls_source_source' do
      find("option[value='#{test_tls_source}']").select_option
    end
    click_on(t('actions.next'))
    expect(page).to have_current_path(pre_flight.checks_path)
    expect(find('.alert-success')).to have_content(t('flash.tls_source', source: test_tls_source))
  end

  it 'runs the pre-flight checks and presents the deploy page' do
    # perform checks before hitting page
    RancherOnAks::VcpuQuotaCheckJob.new.perform(check_id: 1)
    Azure::PublicIpAddressQuotaCheckJob.new.perform(check_id: 2)

    visit(pre_flight.checks_path)
    expect(page).to have_content(t('engines.pre-flight.checks.all_passed'))
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_aks.steps_path)
  end

  it 'deploys the cluster and presents the next steps page' do
    RancherOnAks::Deployment.new.deploy if ENV['RERECORD']
    perform_enqueued_jobs do
      visit(rancher_on_aks.steps_path)
      click_on(t('actions.next')) unless ENV['RERECORD']
    end
    expect(page).to have_current_path(rancher_on_aks.wrapup_path)
  end

  it 'does not re-enable sidebar items' do
    visit(rancher_on_aks.wrapup_path)
    all('.menu-title').each do |menu_entry|
      expect(menu_entry[:class]).to include('disabled')
    end
  end

  it 'offers a download of cleanup commands' do
    visit(rancher_on_aks.wrapup_path)
    click_on(t('actions.download'))
    expect(page.response_headers["Content-Disposition"]).to match('attachment; filename=\"suse-rancher-setup-cleanup-')
  end

  it 'cleans up the resources' do
    visit(rancher_on_aks.wrapup_path)
    perform_enqueued_jobs do
      click_on(t('actions.cleanup'))
    end
    expect(page).to have_current_path(rancher_on_aks.cleanup_path)
    expect(page).to have_content(t('engines.rancher_on_aks.cleanup.success.title'))
  end
end
