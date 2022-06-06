require 'cheetah'
require 'json'

module K8s
  class Cli
    include ActiveModel::Model

    attr_accessor(:kubeconfig, :credential, :region)

    def self.load
      new(
        credential: AWS::Credential.load(),
        region: AWS::Region.load().value,
        kubeconfig: '/tmp/kubeconfig'
      )
    end

    def execute(*args)
      Rails.logger.info "Kubernetes command to run: \'#{args.join(' ')}\'"
      stdout, stderr = Cheetah.run(
        ['kubectl', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => @credential.aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => @credential.aws_secret_access_key,
          'AWS_REGION' => @region,
          'AWS_DEFAULT_REGION' => @region,
          'AWS_DEFAULT_OUTPUT' => 'json',
          'KUBECONFIG' => @kubeconfig
        }
      )
      Rails.logger.info "Command stdout: #{stdout}" if stdout.present?
      Rails.logger.info "Command stderr: #{stderr}" if stderr.present?
      stdout, stderr
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
