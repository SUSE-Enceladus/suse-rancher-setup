module RancherOnEks
  class WrapupJob < ApplicationJob
    queue_as :default

    rescue_from Cheetah::ExecutionFailed, with: :handle_cli_exception
    rescue_from StandardError, with: :handle_cli_exception

    after_perform do |job|
      Rails.configuration.lasso_commands = "done" if Rails.configuration.lasso_run != "true"
      Rails.configuration.lasso_error = "error-cleanup" if Rails.configuration.lasso_error != "" # special value in case there were errors
    end

    def perform(*args)
      RancherOnEks::Deployment.new.rollback
    end

    def handle_cli_exception(exception)
      if exception.class == Cheetah::ExecutionFailed
        Rails.logger.error exception.stderr
        Rails.configuration.lasso_error = exception.stderr
      elsif exception.class == StandardError
        Rails.logger.error exception.message
        Rails.configuration.lasso_error = exception.message
      else
        Rails.logger.error exception
        Rails.configuration.lasso_error = exception
      end
    end
  end
end
