require 'cheetah'
require 'json'

module Helm
  class Cli
    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['helm', *args],
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

    def add_repo(repo_name, repo_url)
      args = %W(
        repo add #{repo_name} #{repo_url}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      args = %W(repo update)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def install_ingress(name_space)
      args = %W(
        upgrade --install
        ingress-nginx ingress-nginx/ingress-nginx
        --namespace #{name_space}
        --set controller.service.type=LoadBalancer
        --version 3.12.0
        --create-namespace
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def install_cert_manager
      args = %W(
        install cert-manager jetstack/cert-manager
        --namespace cert-manager
        --create-namespace
      )
      # TODO: check if version is necessary
      # it works fine without
      # Rancher docs https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/#4-install-cert-manager
      # --version v1.5.1
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_deployment(host_name) # rancher.aws.bear454.com (name_space, host_name) #{name_space} #{host_name}
      args = %W(
        install rancher rancher-stable/rancher
        --namespace cattle-system
        --set hostname=#{host_name}
        --set replicas=3
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    # def delete_deployment(deployment_id)
    #   # TODO
    # end

  end
end
