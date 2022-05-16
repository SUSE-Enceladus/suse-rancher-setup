module RancherOnEks
  class Rancher < Helm::HelmResource
    REPO_NAME = 'rancher-stable'
    REPO_URL = 'https://releases.rancher.com/server-charts/stable'
    RELEASE_NAME = 'rancher-stable'
    CHART = 'rancher-stable/rancher'
    # VERSION = ''
    NAMESPACE = 'cattle-system'
    DEPLOYMENT = 'rancher-stable'

    attr_accessor :fqdn

    def initial_password
      args = %W(
        get secret --namespace #{NAMESPACE} bootstrap-secret
        -o go-template={{.data.bootstrapPassword|base64decode}}
      )
      stdout, stderr = @kubectl.execute(*args)
      return stderr if stderr.present?

      stdout
    end

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
      throw(:abort) unless Rails.application.config.lasso_run.present?

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
