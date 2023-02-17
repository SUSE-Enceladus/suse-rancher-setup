module RancherOnEks
  class CleanupJob < ApplicationJob
    queue_as :default

    discard_on(StandardError) do |job, error|
      Rails.configuration.lasso_error = error.message
    end

    def perform()
      RancherOnEks::Deployment.new.rollback()
    end
  end
end
