module RancherOnEks
  class Rancher < Helm::HelmResource
    REPO_NAME = 'rancher-stable'
    REPO_URL = 'https://releases.rancher.com/server-charts/stable'
    RELEASE_NAME = 'rancher-stable'
    CHART = 'rancher-stable/rancher'
    # VERSION = ''
    NAMESPACE = 'cattle-system'

    attr_accessor :fqdn

    private

    def helm_create
      @kubectl.create_namespace(NAMESPACE)
      @helm.add_repo(REPO_NAME, REPO_URL)
      args = %W(
        --set hostname=#{@fqdn}
        --set replicas=3
      )
      @helm.install(RELEASE_NAME, CHART, NAMESPACE, args)
      self.id = RELEASE_NAME
      self.refresh()
      # self.wait_until(:deployed)
    end

    def helm_destroy
      @helm.delete_deployment(RELEASE_NAME, NAMESPACE)
      @kubectl.delete_namespace(NAMESPACE)
    end

    def describe_resource
      @helm.status(RELEASE_NAME, NAMESPACE)
    end

    def state_attribute
      @framework_attributes['info']['status']
    end
  end
end
