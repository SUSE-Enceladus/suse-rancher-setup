ENV["RAILS_ENV"] ||= "test"
require 'simplecov'
require_relative "../config/environment"
require "rails/test_help"

SimpleCov.command_name("test #{ENV['LASSO_WORKFLOW']}")
class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def mock_login
    put login_url, params: { user: { username: 'username', password: 'password' } }
  end
end
