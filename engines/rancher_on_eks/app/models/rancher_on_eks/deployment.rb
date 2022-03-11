module RancherOnEks
  class Deployment
    def create_steps!
      Step.create!(
        rank: 1,
        action: 'Create a VPC'
      )
      Step.create!(
        rank: 2,
        action: 'Create a Cluster'
      )
    end

    def step(rank)
      step = Step.find_by(rank: rank)
      step.start!
      step.resource = yield
      step.save
      step.complete!
    end

    def deploy
      step(1) do
        @vpc = Aws::Vpc.create
      end
      step(2) do
        Aws::Cluster.create(vpc_id: @vpc.id)
      end
    end
  end
end
