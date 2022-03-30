require 'cheetah'
require 'json'

module Helm
  class Cli
    attr_accessor :kubeconfig

    def initialize(kubeconfig: '/tmp/kubeconfig')
      @kubeconfig = kubeconfig
    end

    def self.load(*args)
      self.new(*args)
    end

    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['helm', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'KUBECONFIG' => @kubeconfig
        }
      )
    end

    def handle_command(args, f=nil)
      if f.nil?
        stdout, stderr = execute(*args)
        return stderr if stderr.present?
        return stdout
      end

      f << args + "\n" if f
    end

    def status(name, namespace)
      args = %W(
        status #{name}
        --namespace #{namespace}
        --show-desc
        --output json
      )
      handle_command(args)
    end

    def add_repo(repo_name, repo_url)
      args = %W(
        repo add #{repo_name} #{repo_url}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      args = %W(repo update)
      handle_command(args)
    end

    def install_load_balancer(name, chart, namespace, version)
      self.install(
        name,
        chart,
        namespace,
        %W(
          --version #{version}
          --set controller.service.type=LoadBalancer
        )
      )
    end

    def install(release_name, chart, namespace, additional_args=[])
      args = %W(
        install #{release_name} #{chart}
        --namespace #{namespace}
      )
      args = args + additional_args
      handle_command(args)
    end

    def delete_deployment(name, namespace, f)
      args = %W(
        uninstall #{name}
        --namespace #{namespace}
        --wait
      )
      handle_command(args, f)
    end
  end
end
