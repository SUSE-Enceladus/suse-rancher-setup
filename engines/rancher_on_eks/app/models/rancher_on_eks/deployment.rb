module RancherOnEks
  class Deployment
    def create_steps!
      Step.create!(
        rank: 1,
        action: 'Create a VPC'
      )
      Step.create!(
        rank: 2,
        action: 'Create Public Subnet 1'
      )
      Step.create!(
        rank: 3,
        action: 'Create Public Subnet 2'
      )
      Step.create!(
        rank: 4,
        action: 'Create Public Subnet 3'
      )
      Step.create!(
        rank: 5,
        action: 'Create Private  Subnet 1'
      )
      Step.create!(
        rank: 6,
        action: 'Create Private Subnet 2'
      )
      Step.create!(
        rank: 7,
        action: 'Create Private Subnet 3'
      )
      Step.create!(
        rank: 8,
        action: 'Create Internet Gateway'
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
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'public',
          zone_index: 0
        )
      end
      step(3) do
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'public',
          zone_index: 1
        )
      end
      step(4) do
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'public',
          zone_index: 2
        )
      end
      step(5) do
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'private',
          zone_index: 0
        )
      end
      step(6) do
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'private',
          zone_index: 1
        )
      end
      step(7) do
        @subnet = Aws::Subnet.create(
          vpc_id: @vpc.id,
          subnet_type: 'private',
          zone_index: 2
        )
      end
      step(8) do
        @ig_id = Aws::InternetGateway.create(vpc_id: @vpc.id)
      end
    end
  end
end
