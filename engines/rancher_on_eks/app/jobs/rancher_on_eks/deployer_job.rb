module RancherOnEks
  class DeployerJob < ApplicationJob
    queue_as :default

    discard_on(StandardError) do |job, error|
      Rails.configuration.lasso_error = error.message
    end

    def perform()
      RancherOnEks::Deployment.new.deploy()
    end
  end
end
