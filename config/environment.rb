# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# Load Pre-Flight Checks from configured workflow
Rails.configuration.workflow.constantize.load_pre_flight_checks!
