module K8s
  class Cli < Executable
    def environment()
      env = {
        'KUBECONFIG' => Rails.configuration.kubeconfig.to_s
      }
      if defined?(AWS::Engine)
        env['AWS_REGION'] = @region
        env['AWS_DEFAULT_REGION'] = @region
        env['AWS_DEFAULT_OUTPUT'] = 'json'
      end
      return env
    end

    def command()
      'kubectl'
    end

    def prepare()
      execute(%w(version --output=json))
    rescue CliError => e
      debugger
      # let kuberlr do its thing
      raise unless e.message.include?('Right kubectl missing, downloading version')
    end

    def status(service_name, namespace)
      args = %W(
        rollout status deployment/#{service_name}
        --namespace #{namespace}
      )
      stdout, stderr = execute(*args)

      response = if stdout.include?('successfully rolled out')
        'deployed'
      elsif stdout.downcase.include?('waiting')
        'waiting'
      else
        'unknown'
      end
    end

    def get_service_name(release_name, namespace)
      args = %W(get services --namespace #{namespace} --output json)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      service = JSON.parse(stdout)['items'].find do |service|
        begin
          service['metadata']['annotations']['meta.helm.sh/release-name'] == release_name
        rescue
          false
        end
      end
      service['metadata']['name']
    end

    def deployments_are_ready?(namespace:)
      args = %W(get deploy --namespace #{namespace} --output json)
      begin
        stdout, stderr = execute(*args)
      rescue CliError => e
        return false
      end
      deployments = JSON.parse(stdout)['items']
      deployments.all? do |deployment|
        deployment['status']['availableReplicas'] == deployment['spec']['replicas']
      end
    end

    def get_load_balancer(release_name, namespace)
      service_name = self.get_service_name(release_name, namespace)
      args = %W(
        get service #{service_name}
        --namespace #{namespace}
        --output json
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      JSON.parse(stdout)
    end

    def get_load_balancer_hostname(release_name, namespace)
      response = self.get_load_balancer(release_name, namespace)
      response['status']['loadBalancer']['ingress'][0]['hostname']
    end

    def get_load_balancer_ip_address(release_name, namespace)
      response = self.get_load_balancer(release_name, namespace)
      response['status']['loadBalancer']['ingress'][0]['ip']
    end

    def get_namespaces
      args = %W(get namespaces --output json)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      namespaces = JSON.parse(stdout)['items'].collect do |namespace|
        namespace['metadata']['name']
      end
    end

    def create_namespace(name)
      return if self.get_namespaces().include?(name)

      args = %W(create namespace #{name})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def update_crds(version:)
      args = %W(
        apply -f https://github.com/jetstack/cert-manager/releases/download/v#{version}/cert-manager.crds.yaml
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def get_pods(name_space)
      args = %W(
        get pods --namespace #{name_space} --output json
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def get_rancher_deployment_status
      args = %W(
        -n cattle-system rollout status deploy/rancher
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end
  end
end
