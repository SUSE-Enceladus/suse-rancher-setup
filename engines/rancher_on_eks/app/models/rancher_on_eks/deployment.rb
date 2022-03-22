module RancherOnEks
  class Deployment
    def create_steps!
      KeyValue.set('tag_scope', "lasso-#{self.random_string()}")
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
        action: "Create a Security Group for the EKS control plane"
      )
      Step.create!(
        rank: 16,
        action: "Define an IAM Role for the EKS control plane"
      )
      Step.create!(
        rank: 17,
        action: 'Create the EKS control plane'
      )
      Step.create!(
        rank: 18,
        action: "Define an IAM Role for the EKS worker nodes"
      )
      Step.create!(
        rank: 19,
        action: 'Create a worker node group in the EKS cluster'
      )
      Step.create!(
        rank: 20,
        action: 'Fetch the kubeconfig for the EKS cluster'
      )
      Step.create!(
        rank: 21,
        action: 'Deploy Ingress controller'
      )
      Step.create!(
        rank: 22,
        action: 'Add DNS entry for Ingress controller'
      )
      Step.create!(
        rank: 23,
        action: 'Deploy Certificate manager'
      )
      Step.create!(
        rank: 24,
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

    def random_string
      # pick a random 4-digit number, return as string
      rand(1000..9999).to_s
    end

    def deploy
      step(0) do
        @cluster_size = RancherOnEks::ClusterSize.new
        @cli = Aws::Cli.load

        zones = @cli.list_availability_zones_supporting_instance_type(
          @cluster_size.instance_type
        )
        if zones.length >= @cluster_size.zones_count
          @zones = zones.sample(@cluster_size.zones_count)
        else
          # if we have less than the required AZ choices, set up multiple
          # subnets in the same AZ, randomly selected
          @zones = zones
          while @zones.length < @cluster_size.zones_count
            @zones << zones.sample()
          end
        end
        @fqdn = RancherOnEks::Fqdn.load()
      end

      step(1) do
        @vpc = Aws::Vpc.create()
        @vpc.wait_until(:available)
      end

      @public_subnets = []
      index = 0
      (2..4).each do |rank|
        step(rank) do
          public_subnet = Aws::PublicSubnet.create(
            vpc_id: @vpc.id,
            index: index,
            zone: @zones[index]
          )
          @public_subnets << public_subnet
          index += 1
          public_subnet.wait_until(:available)
        end
      end
      step(5) do
        @gateway = Aws::InternetGateway.create
        @gateway.attach_to_vpc(@vpc.id)
        @gateway.wait_until(:available)
      end
      step(6) do
        @public_route_table = Aws::RouteTable.create(vpc_id: @vpc.id)
        @cli.create_route(@public_route_table.id, @gateway.id)
        @public_subnets.each do |public_subnet|
          public_subnet.set_route_table!(@public_route_table.id)
        end
        @public_route_table.wait_until(:available)
      end

      @private_subnets = []
      index = 0
      (7..9).each do |rank|
        step(rank) do
          private_subnet = Aws::PrivateSubnet.create(
            vpc_id: @vpc.id,
            index: index,
            zone: @zones[index]
          )
          @private_subnets << private_subnet
          index += 1
          private_subnet.wait_until(:available)
        end
      end
      step(10) do
        @elastic_ip = Aws::AllocationAddress.create()
        @elastic_ip.wait_until(:available)
      end
      step(11) do
        @nat = Aws::NatGateway.create(
          subnet_id: @public_subnets.first.id,
          allocation_address_id: @elastic_ip.id,
          internet_gateway_id: @gateway.id
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
          private_route_table.wait_until(:available)
        end
      end
      step(15) do
        @security_group = Aws::SecurityGroup.create(vpc_id: @vpc.id)
      end
      step(16) do
        @cluster_role = Aws::Role.create(target: 'cluster')
      end
      step(17) do
        subnet_ids =
          @public_subnets.collect(&:id) + @private_subnets.collect(&:id)
        @cluster = Aws::Cluster.create(
          sg_id: @security_group.id,
          role_arn: @cluster_role.arn,
          subnet_ids: subnet_ids
        )
        @cluster.wait_until(:ACTIVE)
      end
      step(18) do
        @ng_role = Aws::Role.create(target: 'nodegroup')
      end
      step(19) do
        @public_subnet_ids = @public_subnets.collect(&:id)
        @nodegroup = Aws::NodeGroup.create(
          cluster_name: @cluster.id,
          role_arn: @ng_role.arn,
          subnet_ids: @public_subnet_ids,
          instance_type: @cluster_size.instance_type,
          instance_count: @cluster_size.instance_count
        )
        @nodegroup.wait_until(:ACTIVE)
      end
      step(20) do
        @cli.update_kube_config(@cluster.id)
        nil
      end
      step(21) do
        @ingress = Helm::IngressController.create()
        @ingress.wait_until(:deployed)
      end
      step(22) do
        @fqdn_record = Aws::DnsRecord.create(
          fqdn: @fqdn.value,
          target: @ingress.hostname(),
          record_type: 'CNAME'
        )
        # @fqdn_record.wait_until(:available)
        # wait loop in DnsRecord is broken FIXME
      end
      step(23) do
        @cert_manager = Helm::CertManager.create()
        @cert_manager.wait_until(:deployed)
      end
      step(24) do
        @rancher = RancherOnEks::Rancher.create(fqdn: @fqdn_record.id)
        @rancher.wait_until(:deployed)
      end
    end

    def rollback
      Step.all.order(rank: :desc).each do |step|
        step.resource&.destroy
        step.destroy
      end
    end
  end
end
