module AWS
  class Role < AWSResource
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

    def create_command
      name = "#{target}-role"
      self.creation_attributes = {
        target: @target
      }
      response = @cli.create_role(name, target)
      self.id = JSON.parse(response)['Role']['RoleName']
      self.wait_until(:available)
      POLICIES_FOR_TARGET[@target].each do |policy|
        @cli.attach_role_policy(self.id, policy)
      end
    end

    def destroy_command
      POLICIES_FOR_TARGET[@target].each do |policy|
        @cli.detach_role_policy(self.id, policy)
      end
      @cli.delete_role(self.id)
      throw(:abort) unless Rails.configuration.lasso_run.present?

      self.wait_until(:not_found) unless Rails.configuration.record_commands
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
