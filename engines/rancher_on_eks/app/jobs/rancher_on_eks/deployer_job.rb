module RancherOnEks
  class DeployerJob < ApplicationJob
    queue_as :default

    rescue_from Cheetah::ExecutionFailed, with: :handle_cli_exception
    rescue_from StandardError, with: :handle_cli_exception

    def perform(*args)
      deployment = RancherOnEks::Deployment.new
      deployment.deploy
    end

    private

    def handle_cli_exception(exception)
      if exception.class == Cheetah::ExecutionFailed
        Rails.logger.error exception.stderr
        Rails.application.config.lasso_error = exception.stderr
      elsif exception.class == StandardError
        Rails.logger.error exception.message
        Rails.application.config.lasso_error = exception.message
      else
        Rails.logger.error exception
        Rails.application.config.lasso_error = exception
      end
    end
  end
end
