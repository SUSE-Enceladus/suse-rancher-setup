require 'json'

module Aws
  class NodeGroup < Resource
    before_create :aws_create_node_group
    before_destroy :aws_delete_node_group

    attr_accessor :vpc_id, :cluster_name

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_node_group(node_group_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_node_group
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      role = Aws::Role.create(role_type: 'nodegroup')
      raw_response = @cli.describe_role("curated-installer-nodegroup-role")
      response = JSON.parse(raw_response)
      role_arn = response['Role']['Arn']

      raw_describe_subnets_response = @cli.describe_subnets(vpc_id)
      subnets = JSON.parse(raw_describe_subnets_response)
      public_subnets_ids = []
      subnets['Subnets'].each do |subnet|
        subnet['Tags'].each do |tag|
          if tag['Key'] == 'Name' && tag['Value'].include?('public')
            public_subnets_ids.append(subnet['SubnetId'])
          end
        end
      end

      describe_cluster_response = @cli.describe_cluster(cluster_name)
      describe_cluster_response = JSON.parse(describe_cluster_response)
      status = describe_cluster_response['cluster']['status']
      while status != 'ACTIVE'
        puts "Waiting (60 seconds) for cluster to be available"
        sleep(60)
        describe_cluster_response = @cli.describe_cluster(cluster_name)
        describe_cluster_response = JSON.parse(describe_cluster_response)
        status = describe_cluster_response['cluster']['status']
        puts status
      end

      self.framework_raw_response = @cli.create_node_group(
        cluster_name, "curated-installer-nodegroup", role_arn, public_subnets_ids
      )
      @response = JSON.parse(self.framework_raw_response)
      describe_nodegroup_response = @cli.describe_node_group(@response['nodegroup']['nodegroupName'], cluster_name)
      describe_nodegroup_response = JSON.parse(describe_nodegroup_response)
      status = describe_nodegroup_response['nodegroup']['status']
      while status != 'ACTIVE'
        puts "Waiting (60 seconds) for nodegroup to be available"
        sleep(60)
        describe_nodegroup_response = @cli.describe_node_group(@response['nodegroup']['nodegroupName'], cluster_name)
        describe_nodegroup_response = JSON.parse(describe_nodegroup_response)
        status = describe_nodegroup_response['nodegroup']['status']
      end

      @cli.update_kube_config(cluster_name)
      self.id = @response['nodegroup']['nodegroupName']
    end

    def aws_delete_role
      @cli ||= Aws::Cli.load
      @cli.delete_internet_gateway(self.id)
    end
  end
end
