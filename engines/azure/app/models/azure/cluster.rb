module Azure
  class Cluster < AzureResource
    attr_accessor :name, :resource_group_name, :k8s_version, :vm_size, :node_resource_group_name

    def azure_create()
      self.creation_attributes = {
        name: @name,
        resource_group_name: @resource_group_name,
        k8s_version: @k8s_version,
        vm_size: @vm_size,
        node_resource_group_name: @node_resource_group_name
      }
      @cli.create_cluster(**self.creation_attributes)
      self.id = @name
      self.refresh()
    end

    def ready!
      self.wait_until('Succeeded')
    end

    def describe_resource()
      @cli.describe_cluster(
        name: @name,
        resource_group_name: @resource_group_name
      )
    end

    def state_attribute()
      @framework_attributes['provisioningState']
    end
  end
end
