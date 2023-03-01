module AWS
  class Kubeconfig < AWSResource
    attr_accessor :cluster

    def create_command
      self.creation_attributes = {
        cluster: @cluster
      }
      @cli.update_kube_config(@cluster)
      K8s::Cli.load.prepare()
      self.id = 'kubeconfig'
    end

    def destroy_command
      @cli.update_kube_config(@cluster) if Rails.configuration.record_commands
    end
  end
end
