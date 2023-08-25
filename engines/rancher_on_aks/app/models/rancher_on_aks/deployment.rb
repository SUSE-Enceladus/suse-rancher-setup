module RancherOnAks
  class Deployment < Deployable
    def create_steps!()
      Step.create!(
        rank: 0,
        duration: 1,
        action: 'Prep',
        cleanup_resource: false
      )
      Step.create!(
        rank: 1,
        duration: 4,
        action: 'Create a resource group'
      )
      Step.create!(
        rank: 2,
        duration: 280,
        action: 'Create an AKS cluster',
        cleanup_resource: false
      )
      Step.create!(
        rank: 3,
        duration: 1,
        action: 'Fetch the kubeconfig for the AKS cluster',
        cleanup_resource: false
      )
      Step.create!(
        rank: 4,
        duration: 40,
        action: 'Wait for system deployments to be ready',
        cleanup_resource: false
      )
      Step.create!(
        rank: 5,
        duration: 50,
        action: 'Deploy the ingress controller',
        cleanup_resource: false
      )
      Step.create!(
        rank: 6,
        duration: 3,
        action: 'Find the IP address of the load balancer',
        cleanup_resource: false
      )
      Step.create!(
        rank: 7,
        duration: 7,
        action: 'Create a DNS record for the Rancher server'
      )
      Step.create!(
        rank: 8,
        duration: 50,
        action: 'Deploy the certificate manager',
        cleanup_resource: false
      )
      Step.create!(
        rank: 9,
        duration: 180,
        action: 'Deploy Rancher',
        cleanup_resource: false
      )
    end

    def deploy()
      step(0, force: true) do
        tag_random_id = self.random_num()
        Rails.logger.debug("TAG RANDOM ID: #{tag_random_id}")
        KeyValue.set('tag_scope', "suse-rancher-setup-#{tag_random_id}")

        @cluster_size = RancherOnAks::ClusterSize.new
        @prefix = KeyValue.get('tag_scope')

        zones = %w(1 2 3) # FIXME - Azure CLI command to look up zones (https://github.com/MicrosoftDocs/azure-docs/issues/40477)
        if zones.length >= @cluster_size.zones_count
          @zones = zones.sample(@cluster_size.zones_count)
        else
          # if we have less than the required zone choices, use what's available
          @zones = zones
        end
        @fqdn = RancherOnAks::Fqdn.load()
        @tls_source = TlsSource.load()
        nil
      end
      step(1) do
        @resource_group = Azure::ResourceGroup.create(name: @prefix)
        @resource_group.ready!
      end
      step(2) do
        @cluster = Azure::Cluster.create(
          name: "#{@prefix}-cluster",
          resource_group: @resource_group,
          k8s_version: Azure::KubernetesInfo.new.latest_matching_version,
          vm_size: @cluster_size.instance_type,
          node_count: @cluster_size.instance_count,
          zones: @zones
        )
        @cluster.ready!
      end
      step(3) do
        @kubeconfig = Azure::Kubeconfig.create(
          cluster: @cluster,
          resource_group: @resource_group
        )
        nil
      end
      step(4) do
        @cluster.deployments_are_ready!
      end
      step(5) do
        @ingress = Helm::IngressController.create()
        @ingress.ready!
      end
      step(6) do
        @public_ip = @ingress.external_ip_address
        nil
      end
      step(7) do
        @dns_record = Azure::DnsRecord.create(
          fqdn: @fqdn,
          target: @public_ip,
          record_type: 'A'
        )
      end
      step(8) do
        @cert_manager = Helm::CertManager.create()
        @cert_manager.ready!
      end
      step(9) do
        @rancher = Helm::Rancher.create(
          fqdn: @fqdn,
          tls_source: @tls_source.source,
          email_address: @tls_source.email_address
        )
        @rancher.ready!
      end
    end
  end
end
