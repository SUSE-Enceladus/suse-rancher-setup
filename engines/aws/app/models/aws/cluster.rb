require 'json'

module Aws
  class Cluster < Resource
    before_create :aws_create_cluster
    before_destroy :aws_delete_cluster

    attr_accessor :vpc_id

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_cluster(cluster_name)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_cluster
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      # create security group
      sg = Aws::SecurityGroup.create(vpc_id: vpc_id)
      # create role
      role = Aws::Role.create(role_type: 'cluster')
      raw_response = @cli.describe_role("curated-installer-cluster-role")
      response = JSON.parse(raw_response)
      role_arn = response['Role']['Arn']
      # get subnets ids
      raw_describe_subnets_response = @cli.describe_subnets(vpc_id)
      subnets = JSON.parse(raw_describe_subnets_response)
      subnets_ids = []
      subnets['Subnets'].each do |subnet|
        subnets_ids.append(subnet['SubnetId'])
      end

      self.framework_raw_response = @cli.create_cluster(
        "curated-installer-cluster", role_arn, subnets_ids.join(","), sg.id
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['cluster']['name']
    end

    def aws_delete_cluster
      @cli ||= Aws::Cli.load
      @cli.delete_cluster(self.id)
    end
  end
end
