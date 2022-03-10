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
      self.id = @response['Cluster']['Name']
    end

    def aws_delete_cluster
      @cli ||= Aws::Cli.load
      @cli.delete_cluster(self.id)
    end
  end
end
