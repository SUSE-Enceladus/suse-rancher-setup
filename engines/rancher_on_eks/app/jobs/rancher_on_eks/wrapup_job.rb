module RancherOnEks
  class WrapupJob < ApplicationJob
    queue_as :default

    after_perform do |job|
      Rails.application.config.lasso_commands = "done" if Rails.application.config.lasso_run != "true"
    end

    def perform(*args)
      RancherOnEks::Deployment.rollback
    end
  end
end
