module Azure
  class KubernetesInfo
    # Class for returning data about kubernetes in Azure
    def initialize(config_version: Rails.configuration.x.rancher_on_aks.k8s_version)
      @config_version = config_version.to_s
      @cli = Azure::Cli.load
    end

    def available_versions
      JSON.parse(@cli.get_kubernetes_versions())
    end

    def latest_matching_version
      matching = self.available_versions.select do |version|
        version.start_with?(@config_version)
      end
      matching.sort.last
    end
  end
end
