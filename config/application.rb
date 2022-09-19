require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SUSERancherSetup
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Asynchronous in-memory background job handler
    config.active_job.queue_adapter = :async

    # Allow all data types in YAML DB embedding
    config.active_record.use_yaml_unsafe_load = true

    config.lasso_run = "run"
    config.lasso_commands = "nil"
    config.lasso_deploy_complete = false
    config.lasso_error = ""
    config.lasso_commands_file = '/var/lib/suse-rancher-setup/delete_resources_steps'
    config.lasso_dns_json_path = '/var/tmp/dns_record.json'
    config.nginx_pass_file = '/etc/nginx/cloudinstancecredentials'
    config.lasso_logged = false
    config.cli_log = 'log/cli.log'
    config.permissions_passed = false

    # External configs: config.yml
    ## Engines to load
    ## The order determines the menu order - engines with no UI should be last
    config.engines = config_for(:config)[:engines]
    ## Application-level menu entries - these come before Engine UIs
    config.menu_entries = [
      { caption: 'Login', icon: 'login', target: '/' },
      { caption: 'Welcome', icon: 'home', target: '/welcome' }
    ]
    # Rancher source - for _helm_
    config.x.rancher = OpenStruct.new(config_for(:config)[:rancher])
    # kubernetes version
    config.x.rancher_on_eks = OpenStruct.new(config_for(:config)[:rancher_on_eks])
  end
end

# Engine loading mechanism
Rails.configuration.engines.each do |engine_name|
  basedir = "#{__dir__}/../engines/"
  engine = engine_name.underscore
  filename = File.expand_path(File.join(basedir, engine, 'lib', "#{engine}.rb"))
  require_relative(filename) if File.exist?(filename)
  Rails.configuration.menu_entries += engine_name.constantize.menu_entries()
end
