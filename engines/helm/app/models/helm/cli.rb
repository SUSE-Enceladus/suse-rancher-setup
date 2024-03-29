module Helm
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
      'helm'
    end

    def status(name, namespace)
      args = %W(
        status #{name}
        --namespace #{namespace}
        --show-desc
        --output json
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

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

    def install_load_balancer(name, chart, namespace, version)
      self.install(
        name,
        chart,
        namespace,
        %W(
          --version #{version}
          --set controller.service.type=LoadBalancer
          --set controller.service.externalTrafficPolicy=Local
        )
      )
    end

    def install(release_name, chart, namespace, additional_args=[])
      args = %W(
        install #{release_name} #{chart}
        --namespace #{namespace}
      )
      args = args + additional_args
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_deployment(name, namespace)
      args = %W(
        uninstall #{name}
        --namespace #{namespace}
      )
      execute(args)
    end
  end
end
