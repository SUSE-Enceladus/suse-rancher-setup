require 'json'

module Aws
  class Role < Resource
    before_create :aws_create_role
    before_destroy :aws_delete_role

    attr_accessor :role_type

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_role(role_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_role
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      if role_type == 'cluster'
        role_name = "curated-installer-cluster-role" # if role_type == 'cluster'
        self.framework_raw_response = @cli.create_role(role_name, role_type)
        @cli.attach_role_policy(role_name, "AmazonEKSClusterPolicy")
        @cli.attach_role_policy(role_name, "AmazonEKSVPCResourceController")
      end
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['Role']['RoleId']
    end

    def aws_delete_role
      @cli ||= Aws::Cli.load
      @cli.delete_internet_gateway(self.id)
    end
  end
end
