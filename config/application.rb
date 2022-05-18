require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CuratedCloudInstaller
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Asynchronous in-memory background job handler
    config.active_job.queue_adapter = :async

    # Engines to load
    # The order determines the menu order - engines with no UI should be last
    config.engines = ['AWS', 'ShirtSize', 'RancherOnEks', 'Helm']

    # Application-level menu entries
    config.menu_entries = [
      { caption: 'Welcome', icon: 'home', target: '/'}
    ]
    config.lasso_run = "run"
    config.lasso_commands = "nil"
    config.lasso_commands_file = '/var/lib/curated-cloud-installer/delete_resources_steps'
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
