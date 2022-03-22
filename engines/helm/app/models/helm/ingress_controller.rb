module Helm
  class IngressController < HelmResource
    REPO_NAME = 'ingress-nginx'
    REPO_URL = 'https://kubernetes.github.io/ingress-nginx'
    RELEASE_NAME = 'ingress-nginx'
    CHART = 'ingress-nginx/ingress-nginx'
    VERSION = '3.12.0'
    NAMESPACE = 'ingress-nginx'

    def hostname
      @kubectl.get_load_balancer_hostname(self.id, NAMESPACE)
    end

    private

    def helm_create
      @kubectl.create_namespace(NAMESPACE)
      @helm.add_repo(REPO_NAME, REPO_URL)
      @helm.install_load_balancer(RELEASE_NAME, CHART, NAMESPACE, VERSION)
      self.id = RELEASE_NAME
      self.refresh()
      # self.wait_until(:deployed)
    end

    def helm_destroy
      @helm.delete_deployment(self.id, NAMESPACE)
      @kubectl.delete_namespace(NAMESPACE)
    end

    def describe_resource
      @helm.status(self.id, NAMESPACE)
    end

    def state_attribute
      @framework_attributes['info']['status']
    end
  end
end
