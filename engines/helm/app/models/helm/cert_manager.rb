module Helm
  class CertManager < HelmResource
    REPO_NAME = 'jetstack'
    REPO_URL = 'https://charts.jetstack.io'
    RELEASE_NAME = 'cert-manager'
    CHART = 'jetstack/cert-manager'
    VERSION = '1.7.1'
    NAMESPACE = 'cert-manager'
    DEPLOYMENT = 'cert-manager'

    def hostname
      @kubectl.get_load_balancer_hostname(RELEASE_NAME, NAMESPACE)
    end

    private

    def helm_create
      @kubectl.create_namespace(NAMESPACE)
      @kubectl.update_crds(version: VERSION)
      @helm.add_repo(REPO_NAME, REPO_URL)
      args = %W(--version #{VERSION})
      @helm.install(RELEASE_NAME, CHART, NAMESPACE, args)
      self.id = RELEASE_NAME
      self.refresh()
    end

    def helm_destroy
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
