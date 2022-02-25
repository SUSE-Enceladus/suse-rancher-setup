require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


# Engine loading mechanism
Dir.glob("#{__dir__}/../engines/*").select { |i| File.directory?(i) }.each do |dir|
  engine_name = File.basename(dir)
  filename = File.expand_path(File.join(dir, 'lib', "#{engine_name}.rb"))
  require_relative(filename) if File.exist?(filename)
end

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
  end
end
