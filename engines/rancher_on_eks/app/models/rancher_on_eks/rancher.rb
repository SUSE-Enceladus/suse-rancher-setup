module RancherOnEks
  class Rancher < Helm::HelmResource
    # VERSION = ''
    NAMESPACE = 'cattle-system'

    attr_accessor :fqdn, :repo_name, :repo_url, :chart, :release_name

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
      @repo_name ||= Rails.application.config.x.rancher.repo_name
      @repo_url ||= Rails.application.config.x.rancher.repo_url
      @chart ||= Rails.application.config.x.rancher.chart
      @release_name ||= Rails.application.config.x.rancher.release_name

      @kubectl.create_namespace(NAMESPACE)
      @helm.add_repo(@repo_name, @repo_url)
      args = %W(
        --set hostname=#{@fqdn}
        --set replicas=3
      )
      @helm.install(@release_name, @chart, NAMESPACE, args)
      self.id = @release_name
      self.refresh()
      # self.wait_until(:deployed)
    end

    def helm_destroy
      @helm.delete_deployment(@release_name, NAMESPACE)
      throw(:abort) unless Rails.application.config.lasso_run.present?

      # @kubectl.delete_namespace(NAMESPACE) # This never completes :(
    end

    def describe_resource
      @helm.status(self.id, NAMESPACE)
    end

    def state_attribute
      @kubectl.status(self.id, NAMESPACE)
    end
  end
end
