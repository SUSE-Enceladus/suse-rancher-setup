require 'cheetah'

module Azure
  class Cli
    class CliError < StandardError; end

    include ActiveModel::Model

    attr_accessor(:tag_scope)

    def self.load()
      cli = new(
        tag_scope: KeyValue.get('tag_scope', 'suse-rancher-setup')
      )
      cli.set_defaults()
      return cli
    end

    def execute(args)
      args.unshift('az').flatten!
      stdout, stderr = Cheetah.run(
        args,
        stdout: :capture,
        stderr: :capture,
        logger: Logger.new(Rails.configuration.cli_log)
      )
      stdout
    rescue Cheetah::ExecutionFailed => e
      Rails.logger.error(
        "Exit status:     #{e.status.exitstatus}\n" \
        "Standard output: #{e.stdout}\n" \
        "Error output:    #{e.stderr}"
      )
      raise CliError.new(e.stderr)
    end

    def set_config(key:, value:)
      self.execute(
        %W(config set #{key}=#{value})
      )
    end

    def get_config(key:)
      stdout = self.execute(
        %W(config get #{key})
      )
      JSON.parse(stdout)['value']
    end

    def set_default_region(region)
      self.set_config(key: 'defaults.location', value: region)
    end

    def set_defaults()
      return if KeyValue.get(:azure_defaults_set, false)

      self.set_config(key: 'core.output', value: 'json')
      self.set_config(key: 'core.disable_confirm_prompt', value: 'true')
      self.set_config(key: 'core.collect_telemetry', value: 'false')
      self.set_config(key: 'core.only_show_errors', value: 'true')
      self.set_config(key: 'core.no_color', value: 'true')
      KeyValue.set(:azure_defaults_set, true)
    end

    def login(app_id:, password:, tenant:)
      # login as a service principal
      # https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli
      response = JSON.parse(self.execute(
        %W(login --service-principal -u #{app_id} -p=#{password} --tenant #{tenant})
      ))
      response.first['user']['name'] == app_id
    end

    def create_resource_group(name:)
      self.execute(
        %W(group create --name #{name})
      )
    end

    def group_exists?(name:)
      response = self.execute(
        %W(group exists --name #{name})
      )
      response.strip == 'true'
    end

    def describe_resource_group(name:)
      self.execute(
        %W(group show --name #{name})
      )
    end

    def destroy_resource_group(name:)
      self.execute(
        %W(
          group delete --name #{name}
          --force-deletion-types Microsoft.Compute/virtualMachines
          --force-deletion-types Microsoft.Compute/virtualMachineScaleSets
        )
      )
    end

    def create_cluster(name:, resource_group:, k8s_version:, vm_size:, node_resource_group:)
      self.execute(
        %W(
          aks create
          --resource-group #{resource_group}
          --name #{name}
          --generate-ssh-keys
          --kubernetes-version #{k8s_version}
          --load-balancer-sku standard
          --node-count 3
          --node-vm-size #{vm_size}
          --node-resource-group #{node_resource_group}
          --zones 1 2 3
        )
      )
    end

    def describe_cluster(name:, resource_group:)
      self.execute(
        %W(aks show --name #{name} --resource-group #{resource_group})
      )
    end

    def update_kubeconfig(cluster:, resource_group:, kubeconfig: '/tmp/kubeconfig')
      self.execute(
        %W(
          aks get-credentials
          --name #{cluster}
          --resource-group #{resource_group}
          --admin
          --file #{kubeconfig}
          --overwrite-existing
        )
      )
    end

    def describe_load_balancer(name:, resource_group:)
      self.execute(
        %W(
          network lb show
          --name #{name}
          --resource-group #{resource_group}
        )
      )
    end

    def describe_public_ip(id:)
      self.execute(
        %W(network public-ip show --ids #{id})
      )
    end
  end
end
