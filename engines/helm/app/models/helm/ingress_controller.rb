module Helm
  class IngressController < HelmResource
    REPO_NAME = 'ingress-nginx'
    REPO_URL = 'https://kubernetes.github.io/ingress-nginx'
    RELEASE_NAME = 'ingress-nginx'
    CHART = 'ingress-nginx/ingress-nginx'
    VERSION = '4.0.18'
    NAMESPACE = 'ingress-nginx'
    DEPLOYMENT = 'ingress-nginx-controller'

    def hostname
      @kubectl.get_load_balancer_hostname(self.id, NAMESPACE)
    end

    def external_ip_address
      @kubectl.get_load_balancer_ip_address(self.id, NAMESPACE)
    end

    def self.release_name
      RELEASE_NAME
    end

    def create_command
      @kubectl.create_namespace(NAMESPACE)
      @helm.add_repo(REPO_NAME, REPO_URL)
      @helm.install_load_balancer(RELEASE_NAME, CHART, NAMESPACE, VERSION)
      self.id = RELEASE_NAME
      self.refresh()
    end

    def destroy_command
      @helm.delete_deployment(RELEASE_NAME, NAMESPACE)
      throw(:abort) unless Rails.configuration.lasso_run.present?
    end

    def describe_resource
      @helm.status(RELEASE_NAME, NAMESPACE)
    end

    def state_attribute
      @kubectl.status(DEPLOYMENT, NAMESPACE)
    end
  end
end
