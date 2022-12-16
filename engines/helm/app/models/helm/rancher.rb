module Helm
  class Rancher < HelmResource
    include ActiveModel::Validations

    NAMESPACE = 'cattle-system'

    attr_accessor :fqdn, :repo_name, :repo_url, :chart, :release_name, :version

    attr_accessor :tls_source
    validates :tls_source, allow_nil: true, inclusion: {
      in: %w(rancher letsEncrypt secret),
      message: "'%{value}' is not valid."
    }

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
      @repo_name ||= Rails.configuration.x.rancher.repo_name
      @repo_url ||= Rails.configuration.x.rancher.repo_url
      @chart ||= Rails.configuration.x.rancher.chart
      @release_name ||= Rails.configuration.x.rancher.release_name
      @version ||= Rails.configuration.x.rancher.version

      @kubectl.create_namespace(NAMESPACE)
      @helm.add_repo(@repo_name, @repo_url)
      args = %W(
        --set extraEnv[0].name=CATTLE_PROMETHEUS_METRICS
        --set-string extraEnv[0].value=true
        --set hostname=#{@fqdn}
        --set replicas=3
      )
      unless @version.blank?
        args << '--version'
        args << @version
      end
      if @tls_source
        args.push(*%W(--set ingress.tls.source=#{@tls_source}))
      end
      @helm.install(@release_name, @chart, NAMESPACE, args)
      self.id = @release_name
      self.refresh()
      #
    end

    def helm_destroy
      @helm.delete_deployment(self.id, NAMESPACE)
    end

    def describe_resource
      @helm.status(self.id, NAMESPACE)
    end

    def state_attribute
      @kubectl.status(self.id, NAMESPACE)
    end
  end
end
