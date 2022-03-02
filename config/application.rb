require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CuratedCloudInstaller
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.engines = [ 'ShirtSize', 'Aws' ]
    config.menu_entries = [
      { caption: 'Welcome', icon: 'home', target: '/' }
    ]
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
