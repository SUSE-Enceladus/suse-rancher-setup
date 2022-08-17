module Helm
  class IngressController < HelmResource
    REPO_NAME = 'ingress-nginx'
    REPO_URL = 'https://kubernetes.github.io/ingress-nginx'
    RELEASE_NAME = 'ingress-nginx'
    CHART = 'ingress-nginx/ingress-nginx'
    VERSION = '4'
    NAMESPACE = 'ingress-nginx'
    DEPLOYMENT = 'ingress-nginx-controller'

    def hostname
      @kubectl.get_load_balancer_hostname(self.id, NAMESPACE)
    end

    def self.release_name
      RELEASE_NAME
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
      @helm.delete_deployment(RELEASE_NAME, NAMESPACE)
      throw(:abort) unless Rails.configuration.lasso_run.present?
      # @kubectl.delete_namespace(NAMESPACE) # This never completes :(
    end

    def describe_resource
      @helm.status(RELEASE_NAME, NAMESPACE)
    end

    def state_attribute
      @kubectl.status(DEPLOYMENT, NAMESPACE)
    end
  end
end
