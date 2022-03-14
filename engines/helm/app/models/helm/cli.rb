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

    # def describe_deployment(node_group_name)
    #   # TODO
    # end

    def create_deployment(node_group_name)
      repo_url = "https://kubernetes.github.io/ingress-nginx"
      repo_name = "ingress-nginx"
      _add_repo(repo_name, repo_url)
      _install_ingress(repo_name)
      _get_load_balancer_ip(repo_name)
    end

    def _add_repo(repo_name, repo_url)
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

    def _install_ingress(name_space)
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

    def _get_load_balance_ip(name_space)
      args = %W(
        kubectl get service ingress-nginx-controller
        --namespace #{name_space} --output json
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
