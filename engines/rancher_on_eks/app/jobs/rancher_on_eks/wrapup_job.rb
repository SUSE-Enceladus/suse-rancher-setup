module RancherOnEks
  class WrapupJob < ApplicationJob
    queue_as :default

    after_perform do |job|
      Rails.application.config.lasso_commands = "done" if Rails.application.config.lasso_run != "true"
      Rails.application.config.lasso_error = "error-cleanup" if Rails.application.config.lasso_error != "" # special value in case there were errors
    end

    def perform(*args)
      RancherOnEks::Deployment.rollback
    end
  end
end
