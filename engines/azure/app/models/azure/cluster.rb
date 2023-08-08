module Azure
  class Cluster < AzureResource
    attr_accessor :name, :resource_group, :k8s_version, :vm_size, :node_count, :zones

    def to_s
      @name
    end

    def create_command()
      self.creation_attributes = {
        name: @name,
        resource_group: @resource_group,
        k8s_version: @k8s_version,
        vm_size: @vm_size
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

    def deployments_are_ready!
      deployments_are_ready = false
      kubectl = K8s::Cli.load

      while !deployments_are_ready
        logger.info "#{self.type} #{self.id} waiting for deployments_are_ready..."
        deployments_are_ready = kubectl.deployments_are_ready?(namespace: 'kube-system')
        sleep(10) unless deployments_are_ready
      end
    end

    def describe_resource()
      @cli.describe_cluster(
        name: @name,
        resource_group: @resource_group
      )
    end

    def state_attribute()
      @framework_attributes['properties']['provisioningState']
    end
  end
end
