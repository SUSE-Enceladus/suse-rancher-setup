module RancherOnEks
  class Deployment
    def create_steps!
      Step.create!(
        rank: 1,
        action: 'Create a VPC'
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
    end
  end
end
