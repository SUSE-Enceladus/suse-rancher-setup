module Azure
  class Cli < Executable
    def initialize(**args)
      super(**args)
      set_defaults()
    end

    def environment()
      {}
    end

    def command()
      'az'
    end

    def set_config(key:, value:)
      self.execute(
        %W(config set #{key}=#{value})
      )
    rescue CliError => e
      # older CLI versions carried a warning, which we can ignore
      raise unless e.message.include?("Command group 'config' is experimental and not covered by customer support. Please use with discretion.")
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
        )
      )
    end

    def create_cluster(name:, resource_group:, k8s_version:, vm_size:, node_count: 3, node_resource_group:, zones: %w(1 2 3))
      self.execute(
        %W(
          aks create
          --resource-group #{resource_group}
          --name #{name}
          --generate-ssh-keys
          --kubernetes-version #{k8s_version}
          --load-balancer-sku standard
          --node-count #{node_count}
          --node-vm-size #{vm_size}
          --node-resource-group #{node_resource_group}
          --zones
        ).push(zones)
      )
    end

    def describe_cluster(name:, resource_group:)
      self.execute(
        %W(aks show --name #{name} --resource-group #{resource_group})
      )
    end

    def update_kubeconfig(cluster:, resource_group:, kubeconfig: Rails.configuration.kubeconfig)
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

    def find_resource_group_for_dns_zone(zone:)
      response = JSON.parse(
        self.execute(
          %W(network dns zone list)
        )
      )
      begin
        response.select{ |resource| resource['name'] == zone }.first['resourceGroup']
      rescue NoMethodError
        nil
      end
    end

    def create_dns_record(resource_group:, record_type:, record:, domain:, target:)
      args = %W(
        network dns record-set #{record_type.downcase} add-record
        --resource-group #{resource_group}
        --record-set-name #{record}
        --zone-name #{domain}
      )
      case record_type
      when 'A'
        args.push('--ipv4-address', target)
      end
      self.execute(args)
    end

    def describe_dns_record(resource_group:, record_type:, record:, domain:)
      self.execute(
        %W(
          network dns record-set #{record_type.downcase} show
          --resource-group #{resource_group}
          --name #{record}
          --zone-name #{domain}
        )
      )
    end

    def destroy_dns_record(resource_group:, record_type:, record:, domain:)
      self.execute(
        %W(
          network dns record-set #{record_type.downcase} delete
          --resource-group #{resource_group}
          --name #{record}
          --zone-name #{domain}
        )
      )
    end

    def list_sizes(region:)
      self.execute(
        %W(
          vm list-sizes --location #{region}
        )
      )
    end

    def describe_instance_type(instance_type)
      self.execute(
        %W(
          vm list-skus --size #{instance_type}
        )
      )
    end

    def list_vcpu_usage(family:)
      self.execute(
        %W(
          vm list-usage --query [?name.value=='#{family}']
        )
      )
    end

    def list_network_usage(value:)
      self.execute(
        %W(
          network list-usages --query [?name.value=='#{value}']
        )
      )
    end

    def get_kubernetes_versions()
      self.execute(
        %w(aks get-versions --query orchestrators[].orchestratorVersion)
      )
    end
  end
end
