module RancherOnAks
  class DeployerJob < ApplicationJob
    queue_as :default

    discard_on(StandardError) do |job, error|
      Rails.configuration.lasso_error = error.message
    end

    def perform()
      RancherOnAks::Deployment.new.deploy()
    end
  end
end
