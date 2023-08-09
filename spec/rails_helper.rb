# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'fileutils'
require 'yaml'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
  config.include ActiveJob::TestHelper
end

def azure_test_credentials
  $app_id ||= ENV['APP_ID'] || Faker::Internet.uuid
  $password ||= ENV['PASSWORD'] || 'password'
  $tenant ||= ENV['TENANT'] || Faker::Internet.uuid
  $subscription ||= ENV['SUBSCRIPTION'] || Faker::Internet.uuid

  [
    $app_id,
    $password,
    $tenant,
    $subscription
  ]
end

def mock_azure_login(credentials=azure_test_credentials())
  app_id, password, tenant, subscription = credentials
  Azure::Credential.new(
    app_id: app_id,
    password: password,
    tenant: tenant
  ).save(validate: false)
  Azure::Subscription.new(value: subscription).save
end

VCR.configure do |config|
  config.cassette_library_dir = "#{::Rails.root}/spec/vcr"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.ignore_hosts '127.0.0.1'
  config.default_cassette_options = {
    match_requests_on: [:method, :host, :path],
    decode_compressed_response: true,
    record: :new_episodes
  }
  app_id, password, tenant, subscription = azure_test_credentials()
  config.filter_sensitive_data("[app_id]") { app_id }
  config.filter_sensitive_data("[password]") { password }
  config.filter_sensitive_data("[password_encoded]") { URI.encode_www_form_component(password) }
  config.filter_sensitive_data("[tenant]") { tenant }
  config.filter_sensitive_data("[subscription]") { subscription }

  config.filter_sensitive_data('[token]') do |interaction|
    begin
      JSON.parse(interaction.response.body)['access_token']
    rescue StandardError
      nil
    end
  end
  config.filter_sensitive_data('[token]') do |interaction|
    begin
      interaction.request.headers['Authorization'].first
    rescue StandardError
      nil
    end
  end

  config.configure_rspec_metadata!
end

def cheetah_vcr(context:, force_recording: false)
  allow(Cheetah).to receive(:run).and_wrap_original do |method, *args|
    cli_args = args.first
    fixture_dir = Rails.root.join('spec', 'vcr', context)
    filename = Digest::MD5.hexdigest(cli_args.flatten.join(' ')) + '.yaml'
    fixture_path = fixture_dir.join(filename)
    FileUtils.mkdir_p(fixture_dir)
    update_vcr_map(fixture_dir: fixture_dir, digest: filename, cli_args: cli_args) unless ENV['CI']
    puts("Using #{fixture_path} for args '#{cli_args.join(' ')}'") if ENV['DEBUG']
    if File.exists?(fixture_path) && !force_recording
      YAML.load_file(fixture_path)
    else
      begin
        result = method.call(*args)
      rescue Cheetah::ExecutionFailed => e
        result = [e.stdout, e.stderr]
        raise
      ensure
        puts("Writing #{fixture_path} from args '#{cli_args.join(' ')}'")
        File.open(fixture_path, 'w') { |file| file.write(YAML.dump(result)) }
      end
      result
    end
  end
end

def update_vcr_map(fixture_dir:, digest:, cli_args:)
  map_filename = fixture_dir.join('map')
  FileUtils.touch(map_filename)
  File.foreach(map_filename) do |map_line|
    stored_digest = map_line.split("\t").first
    return if stored_digest == digest

  end
  File.open(map_filename, 'a') do |map|
    map.write(digest, "\t", cli_args.join(' '), "\n")
  end
end

puts("rails_helper loaded")
