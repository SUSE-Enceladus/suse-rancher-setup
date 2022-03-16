require 'cheetah'
require 'json'

module K8s
  class Cli
    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['kubectl', *args],
        stdout: :capture,
        stderr: :capture,
        env: {}
      )
    end

    def self.load
      new
    end


    # def describe_deployment(node_group_name)
    #   # TODO
    # end

    def get_load_balancer_ip(name_space)
      args = %W(
        get service ingress-nginx-controller
        --namespace #{name_space}
        --output json
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_namespace
      args = %W(
        create namespace cattle-system
      )
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
