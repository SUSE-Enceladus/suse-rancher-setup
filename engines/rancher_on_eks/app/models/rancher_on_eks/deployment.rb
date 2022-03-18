module RancherOnEks
  class Deployment
    def create_steps!
      KeyValue.set('tag_scope', 'ranchers-spouse')
      Step.create!(
        rank: 0,
        action: 'Prep'
      )
      Step.create!(
        rank: 1,
        action: 'Create a VPC'
      )

      index = 1
      (2..4).each do |rank|
        Step.create!(
          rank: rank,
          action: "Create public subnet #{index}/3"
        )
        index += 1
      end

      Step.create!(
        rank: 5,
        action: 'Create an Internet Gateway for public subnets'
      )
      Step.create!(
        rank: 6,
        action: 'Route public subnets through Internet Gateway'
      )

      index = 1
      (7..9).each do |rank|
        Step.create!(
          rank: rank,
          action: "Create private subnet #{index}/3"
        )
        index += 1
      end

      Step.create!(
        rank: 10,
        action: 'Secure an Elastic IP address'
      )
      Step.create!(
        rank: 11,
        action: 'Create a NAT Gateway for private subnets on Elastic IP address'
      )

      index = 1
      (12..14).each do |rank|
        Step.create!(
          rank: rank,
          action: "Route private subnet #{index}/3 through NAT Gateway"
        )
        index += 1
      end
      Step.create!(
        rank: 15,
        action: 'Create a Cluster'
      )
      Step.create
        rank: 16,
        action: 'Create a Node Group'
      )
      Step.create!(
        rank: 17,
        action: 'Deploy Rancher'
      )
    end

    def step(rank)
      step = Step.find_by(rank: rank)
      return if step.complete?
      step.start!
      step.resource = yield if block_given?
      step.save
      step.complete!
    end

    def deploy
      step(0) do
        @cluster_size = RancherOnEks::ClusterSize.new
        @cli = Aws::Cli.load

        zones = @cli.list_availability_zones_supporting_instance_type(
          @cluster_size.instance_type
        )
        if zones.length >= 3
          @zones = zones.sample(3)
        else
          # if we have less than 3 AZ choices, set up multiple subnets in the
          # same AZ, randomly selected
          @zones = zones
          while @zones.length < 3
            @zones << zones.sample()
          end
        end
      end

      step(1) do
        @vpc = Aws::Vpc.create()
      end

      @public_subnets = []
      index = 0
      (2..4).each do |rank|
        step(rank) do
          public_subnet = Aws::Subnet.create(
            vpc_id: @vpc.id,
            subnet_type: 'public',
            index: index,
            zone: @zones[index]
          )
          public_subnet.map_public_ips!
          @public_subnets << public_subnet
          index += 1
          public_subnet
        end
      end
      step(5) do
        @gateway = Aws::InternetGateway.create(vpc_id: @vpc.id)
        @gateway
      end
      step(6) do
        @public_route_table = Aws::RouteTable.create(vpc_id: @vpc.id)
        @cli.create_route(@public_route_table.id, @gateway.id)
        @public_subnets.each do |public_subnet|
          public_subnet.set_route_table!(@public_route_table.id)
        end
        @public_route_table
      end

      @private_subnets = []
      index = 0
      (7..9).each do |rank|
        step(rank) do
          private_subnet = Aws::Subnet.create(
            vpc_id: @vpc.id,
            subnet_type: 'private',
            index: index,
            zone: @zones[index]
          )
          @private_subnets << private_subnet
          index += 1
          private_subnet
        end
      end
      step(10) do
        @elastic_ip = Aws::AllocationAddress.create()
      end
      step(11) do
        @nat = Aws::NatGateway.create(
          subnet_id: @public_subnets.first.id,
          allocation_address_id: @elastic_ip.id
        )
        @nat.wait_until(:available)
      end
      @private_route_tables = []
      index = 0
      (12..14).each do |rank|
        step(rank) do
          private_subnet = @private_subnets[index]
          private_route_table = Aws::RouteTable.create(vpc_id: @vpc.id, name: "private-route-table-#{index}")
          private_subnet.set_route_table!(private_route_table.id)
          @private_route_tables << private_route_table
          index += 1
          private_route_table
        end
      end
      step(15) do
        @cluster = Aws::Cluster.create(vpc_id: @vpc.id)
      end
      step(16) do
        Aws::NodeGroup.create(vpc_id: @vpc.id, cluster_name: @cluster.id)
      end
      step(17) do
        Helm::Deployment.create
      end
    end
  end
end
