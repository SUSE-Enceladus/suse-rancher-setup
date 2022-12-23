module RancherOnAks
  class Deployment < Deployable
    def create_steps!()
      Step.create!(
        rank: 0,
        duration: 1,
        action: 'Prep'
      )
      Step.create!(
        rank: 1,
        duration: 4,
        action: 'Create a resource group'
      )
      Step.create!(
        rank: 2,
        duration: 280,
        action: 'Create an AKS cluster'
      )
      Step.create!(
        rank: 3,
        duration: 1,
        action: 'Fetch the kubeconfig for the AKS cluster'
      )
      Step.create!(
        rank: 4,
        duration: 50,
        action: 'Deploy the ingress controller'
      )
      Step.create!(
        rank: 5,
        duration: 3,
        action: 'Find the IP address of the load balancer'
      )
      Step.create!(
        rank: 6,
        duration: 7,
        action: 'Create a DNS record for the Rancher server'
      )
      Step.create!(
        rank: 7,
        duration: 50,
        action: 'Deploy the certificate manager'
      )
      Step.create!(
        rank: 8,
        duration: 180,
        action: 'Deploy Rancher'
      )
    end

    def deploy()
      step(0, force: true) do
        KeyValue.set('tag_scope', "suse-rancher-setup-#{self.random_num()}")

        @cluster_size = RancherOnAks::ClusterSize.new
        @prefix = KeyValue.get('tag_scope')
        @cli = Azure::Cli.load()

        zones = %w(1 2 3) # FIXME - Azure CLI command to look up zones (https://github.com/MicrosoftDocs/azure-docs/issues/40477)
        if zones.length >= @cluster_size.zones_count
          @zones = zones.sample(@cluster_size.zones_count)
        else
          # if we have less than the required zone choices, use what's available
          @zones = zones
        end
        @fqdn = RancherOnAks::Fqdn.load()
        nil
      end
      step(1) do
        @resource_group = Azure::ResourceGroup.create(name: @prefix)
        @resource_group.ready!
      end
      step(2) do
        @cluster = Azure::Cluster.create(
          name: "#{@prefix}_cluster",
          resource_group: @resource_group,
          k8s_version: Rails.configuration.x.rancher_on_aks.k8s_version,
          vm_size: @cluster_size.instance_type,
          node_count: @cluster_size.instance_count,
          node_resource_group: "#{@prefix}_nodes",
          zones: @zones
        )
        @cluster.ready!
        nil
      end
      step(3) do
        @cli.update_kubeconfig(
          cluster: @cluster,
          resource_group: @resource_group
        )
        nil
      end
      step(4) do
        @ingress = Helm::IngressController.create()
        @ingress.ready!
        nil
      end
      step(5) do
        @load_balancer = Azure::LoadBalancer.load(
          resource_group: @cluster.creation_attributes[:node_resource_group]
        )
        @public_ip = @load_balancer.public_ip
        @public_ip.save
        nil
      end
      step(6) do
        @dns_record = Azure::DnsRecord.create(
          fqdn: @fqdn,
          target: @public_ip,
          record_type: 'A'
        )
      end
      step(7) do
        @cert_manager = Helm::CertManager.create()
        @cert_manager.ready!
        nil
      end
      step(8) do
        @rancher = Helm::Rancher.create(
          fqdn: @fqdn
        )
        @rancher.ready!
        nil
      end
      Rails.configuration.lasso_deploy_complete = true
    end
  end
end
