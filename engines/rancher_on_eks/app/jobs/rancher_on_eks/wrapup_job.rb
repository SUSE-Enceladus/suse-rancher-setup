module RancherOnEks
  class WrapupJob < ApplicationJob
    queue_as :default

    after_perform do |job|
      Rails.configuration.lasso_commands = "done" if Rails.configuration.lasso_run != "true"
      Rails.configuration.lasso_error = "error-cleanup" if Rails.configuration.lasso_error != "" # special value in case there were errors
    end

    def perform(*args)
      RancherOnEks::Deployment.new.rollback
    end
  end
end
