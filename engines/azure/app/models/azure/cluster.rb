module Azure
  class Cluster < AzureResource
    attr_accessor :name, :resource_group, :k8s_version, :vm_size, :node_count, :node_resource_group, :zones

    def to_s
      @name
    end

    def create_command()
      self.creation_attributes = {
        name: @name,
        resource_group: @resource_group,
        k8s_version: @k8s_version,
        vm_size: @vm_size,
        node_resource_group: @node_resource_group
      }
      @cli.create_cluster(**self.creation_attributes)
      self.id = @name
      self.refresh()
    end

    def destroy_command()
      # not implemented
    end

    def ready!
      self.wait_until('Succeeded')
    end

    def describe_resource()
      @cli.describe_cluster(
        name: @name,
        resource_group: @resource_group
      )
    end

    def state_attribute()
      @framework_attributes['provisioningState']
    end
  end
end
