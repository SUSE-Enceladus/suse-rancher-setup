module RancherOnEks
  class DeployerJob < ApplicationJob
    queue_as :default

    def perform(*args)
      deployment = RancherOnEks::Deployment.new
      deployment.deploy
    end
  end
end
