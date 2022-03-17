module RancherOnEks
  class Deployment
    def create_steps!
      KeyValue.set('tag_scope', 'ranchers-spouse')

      Step.create!(
        rank: 1,
        action: 'Create a VPC'
      )
      Step.create!(
        rank: 2,
        action: 'Create a Cluster'
      )
      Step.create!(
        rank: 3,
        action: 'Create a Node Group'
      )
      Step.create!(
        rank: 4,
        action: 'Deploy Rancher'
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
        @cluster = Aws::Cluster.create(vpc_id: @vpc.id)
      end
      step(3) do
        Aws::NodeGroup.create(vpc_id: @vpc.id, cluster_name: @cluster.id)
      end
      step(4) do
        Helm::Deployment.create
      end

    end
  end
end
