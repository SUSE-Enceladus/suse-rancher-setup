require 'json'

module AWS
  class NodeGroup < AWSResource
    attr_accessor :cluster_name, :role_arn, :subnet_ids,
                  :instance_type, :instance_count

    private

    def aws_create
      self.creation_attributes = {
        cluster_name: @cluster_name,
        role_arn: @role_arn,
        subnet_ids: @subnet_ids,
        instance_type: @instance_type,
        instance_count: @instance_count
      }
      response = @cli.create_node_group(
        @cluster_name, @role_arn, @subnet_ids, @instance_type, @instance_count
      )
      self.id = JSON.parse(response)['nodegroup']['nodegroupName']
      # self.wait_until(:ACTIVE)
    end

    def aws_destroy
      @cli.delete_node_group(self.id, @cluster_name)
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_node_group(self.id, @cluster_name)
    end

    def state_attribute
      @framework_attributes['nodegroup']['status']
    end
  end
end
