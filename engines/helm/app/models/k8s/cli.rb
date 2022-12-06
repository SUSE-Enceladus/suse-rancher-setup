require 'cheetah'
require 'json'

module K8s
  class Cli
    include ActiveModel::Model

    attr_accessor(:kubeconfig, :region)

    def self.load
      new(
        region: (AWS::Region.load().value if defined?(AWS::Engine)),
        kubeconfig: '/tmp/kubeconfig'
      )
    end

    def execute(*args)
      env = {
        'KUBECONFIG' => @kubeconfig
      }
      if defined?(AWS::Engine)
        env['AWS_REGION'] = @region
        env['AWS_DEFAULT_REGION'] = @region
        env['AWS_DEFAULT_OUTPUT'] = 'json'
      end
      stdout, stderr = Cheetah.run(
        ['kubectl', *args],
        stdout: :capture,
        stderr: :capture,
        env: env,
        logger: Logger.new(Rails.configuration.cli_log)
      )
    end

    def status(service_name, namespace)
      args = %W(
        rollout status deployment/#{service_name}
        --namespace #{namespace}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

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

    def get_load_balancer_hostname(release_name, namespace)
      service_name = self.get_service_name(release_name, namespace)
      args = %W(
        get service #{service_name}
        --namespace #{namespace}
        --output json
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      JSON.parse(stdout)['status']['loadBalancer']['ingress'][0]['hostname']
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

    def update_cdr
      args = %W(
        apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml
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
