require 'cheetah'

module Helm
  class Cli
    include ActiveModel::Model
    attr_accessor(:region, :kubeconfig)

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
        ['helm', *args],
        stdout: :capture,
        stderr: :capture,
        env: env,
        logger: Logger.new(Rails.configuration.cli_log)
      )
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
          --set controller.watchIngressWithoutClass=true
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
      handle_command(args)
    end

    def handle_command(args)
      if Rails.configuration.lasso_run.present?
        stdout, stderr = execute(*args)
        return stderr if stderr.present?
        return stdout
      else
        File.open(Rails.configuration.lasso_commands_file, 'a') do |f|
          envs = "KUBECONFIG=#{@kubeconfig}"
          f.write "#{envs} helm #{args.join(' ')} --region #{@region} --output json\n"
        end
      end
    end
  end
end
