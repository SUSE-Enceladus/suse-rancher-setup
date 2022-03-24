module Helm
  class CertManager < HelmResource
    REPO_NAME = 'jetstack'
    REPO_URL = 'https://charts.jetstack.io'
    RELEASE_NAME = 'cert-manager'
    CHART = 'jetstack/cert-manager'
    VERSION = '1.5.1'
    NAMESPACE = 'cert-manager'

    def hostname
      @kubectl.get_load_balancer_hostname(RELEASE_NAME, NAMESPACE)
    end

    private

    def helm_create
      @kubectl.create_namespace(NAMESPACE)
      @kubectl.update_cdr()
      @helm.add_repo(REPO_NAME, REPO_URL)
      args = %W(--version #{VERSION})
      @helm.install(RELEASE_NAME, CHART, NAMESPACE, args)
      self.id = RELEASE_NAME
      self.refresh()
      # self.wait_until(:deployed)
    end

    def helm_destroy(f=nil)
      @helm.delete_deployment(RELEASE_NAME, NAMESPACE, f)
      # @kubectl.delete_namespace(NAMESPACE) # This never completes :(
    end

    def describe_resource
      @helm.status(RELEASE_NAME, NAMESPACE)
    end

    def state_attribute
      @framework_attributes['info']['status']
    end
  end
end
