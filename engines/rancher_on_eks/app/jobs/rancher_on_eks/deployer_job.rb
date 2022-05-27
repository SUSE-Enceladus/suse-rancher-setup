module RancherOnEks
  class DeployerJob < ApplicationJob
    queue_as :default

    rescue_from Cheetah::ExecutionFailed, with: :handle_cli_exception

    def perform(*args)
      deployment = RancherOnEks::Deployment.new
      deployment.deploy
    end

    private

    def handle_cli_exception(exception)
      Rails.application.config.lasso_error = exception.stderr
    end
  end
end
