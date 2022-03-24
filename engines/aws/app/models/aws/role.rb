module Aws
  class Role < AwsResource
    attr_accessor :target

    POLICIES_FOR_TARGET = {
      'cluster' => [
        'AmazonEKSClusterPolicy',
        'AmazonEKSVPCResourceController'
      ],
      'nodegroup' => [
        'AmazonSSMManagedInstanceCore',
        'AmazonEKS_CNI_Policy',
        'AmazonEC2ContainerRegistryReadOnly',
        'AmazonEKSWorkerNodePolicy'
      ]
    }

    def arn
      @framework_attributes['Role']['Arn']
    end

    private

    def aws_create
      name = "#{target}-role"
      response = @cli.create_role(name, target)
      self.id = JSON.parse(response)['Role']['RoleName']
      self.wait_until(:available)
      POLICIES_FOR_TARGET[@target].each do |policy|
        @cli.attach_role_policy(self.id, policy)
      end
    end

    def aws_destroy(f=nil)
      policies = JSON.parse(@cli.list_role_attached_policies(self.id))
      policies['AttachedPolicies'].each do |policy|
        @cli.detach_role_policy(self.id, policy['PolicyArn'], f)
      end
      @cli.delete_role(self.id, f)
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_role(self.id)
    end

    def state_attribute
      if @framework_attributes['State']
        @framework_attributes['State']
      elsif @framework_attributes['Role']
        'available'
      end
    end
  end
end
