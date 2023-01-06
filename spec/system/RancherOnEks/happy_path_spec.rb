require 'web_helper'

return unless defined?(RancherOnEks::Engine)

RSpec::Steps.steps('RancherOnEks: small cluster', type: :system) do
  let(:test_region) { 'us-west-2' }
  let(:test_shirt_size) { 'small' }
  let(:test_fqdn) { "rancher-setup-test.aws.bear454.com" }
  let(:test_tls_source) { "rancher" }

  before(:all) do
    driven_by(:rack_test)
  end

  before(:example) do
    allow_any_instance_of(Deployable).to receive(:random_num).and_return(1327)
    allow_any_instance_of(RancherOnEks::Fqdn).to receive(:dns_record_exist?).and_return(false)
    cheetah_vcr()
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
    expect(page).to have_text(t('workflow.rancher_on_eks.product_brand.title'))
    expect(page).to have_text(t('workflow.rancher_on_eks.greeting.content'))
  end

  it 'checks IAM permissions after welcome' do
    visit(main_app.welcome_path)
    click_on(t('actions.next'))
    expect(page).to have_current_path(aws.permissions_path)
    expect(page).to have_content(t('engines.aws.permissions.passed'))
  end

  it 'presents the region choice after IAM permissions' do
    visit(aws.permissions_path)
    click_on(t('actions.next'))
    expect(page).to have_current_path(aws.edit_region_path)
    expect(page).to have_content(t('engines.aws.region.title'))
    expect(page).to have_content(t('engines.aws.region.form_caption'))
  end

  it 'sets a region and presents the cluster sizing page' do
    visit(aws.edit_region_path)
    select(test_region, from: 'region_value')
    click_on(t('actions.next'))
    expect(page).to have_current_path(shirt_size.edit_size_path)
    expect(find('.alert-success')).to have_content(t('engines.aws.region.using', region: test_region))
  end

  it 'sets the cluster size and presents the FQDN page' do
    visit(shirt_size.edit_size_path)
    choose(t("engines.shirt_size.sizes.labels.#{test_shirt_size}"))
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_eks.edit_fqdn_path)
    expect(find('.alert-success')).to have_content(t('engines.shirt_size.sizes.using', size: test_shirt_size))
  end

  it 'sets the FQDN and presents the security page' do
    visit(rancher_on_eks.edit_fqdn_path)
    fill_in('fqdn_value', with: test_fqdn)
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_eks.edit_security_path)
    expect(find('.alert-success')).to have_content(t('flash.using_fqdn', fqdn: test_fqdn))
  end

  it 'selects a certificate source and presents the deploy page' do
    visit(rancher_on_eks.edit_security_path)
    within 'select#tls_source_source' do
      find("option[value='#{test_tls_source}']").select_option
    end
    click_on(t('actions.next'))
    expect(page).to have_current_path(rancher_on_eks.steps_path)
    expect(find('.alert-success')).to have_content(t('flash.tls_source', source: test_tls_source))
  end

  it 'deploys the cluster and presents the next steps page' do
    perform_enqueued_jobs do
      visit(rancher_on_eks.steps_path)
      click_on(t('actions.next'))
    end
    expect(page).to have_current_path(rancher_on_eks.wrapup_path)
  end
end
