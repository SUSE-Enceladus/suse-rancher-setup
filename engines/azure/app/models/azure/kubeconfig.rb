module Azure
  class Kubeconfig < AzureResource
    attr_accessor :cluster, :resource_group

    def create_command()
      self.creation_attributes = {
        cluster: @cluster,
        resource_group: @resource_group
      }
      @cli.update_kubeconfig(
        cluster: @cluster,
        resource_group: @resource_group
      )
      K8s::Cli.load.prepare()
      self.id = 'kubeconfig'
      self
    end

    def destroy_command()
      @cli.update_kubeconfig(
        cluster: @cluster,
        resource_group: @resource_group
      ) if Rails.configuration.record_commands
    end
  end
end
