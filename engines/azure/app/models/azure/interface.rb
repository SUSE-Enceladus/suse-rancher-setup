module Azure
  require 'base64'

  class Interface
    class LoginError < StandardError; end

    HOST = 'https://management.azure.com/'

    # Most calls use the current API version as of development
    DEFAULT_API_VERSION = '2023-07-01'
    # Some APIs respond inconsistently wiht docs using the current API version,
    # so we use the documented API version for those calls.
    DNS_API_VERSION = '2018-05-01'
    AKS_API_VERSION = '2023-05-01'
    VM_SIZES_API_VERSION = '2023-03-01'
    NETWORK_API_VERSION = '2023-02-01'

    attr_accessor(:credential, :subscription, :region, :token)

    def self.load
      new(
        credential: Azure::Credential.last,
        subscription: Azure::Subscription.load(),
        region: Azure::Region.load()
      )
    end

    def initialize(credential:, subscription:, region:)
      @credential = credential
      @subscription = subscription
      @region = region
    end

    def login(credentials: @credential.creation_attributes)
      if @subscription.value.blank?
        @subscription.value = Azure::Metadata.get_subscription()
        @subscription.save!
      end
      @token = get_token(**credentials)
    rescue RestClient::ExceptionWithResponse => e
      raise(LoginError.new(
        JSON.parse(e.response.body)['error_description']
      ))
    rescue StandardError => e
      raise(LoginError.new(e.message))
    end

    def get_token(app_id:, password:, tenant:)
      response = RestClient.post(
        tenant_oauth_token_url(tenant: tenant),
        {
          'grant_type' => 'client_credentials',
          'client_id' => app_id,
          'client_secret' => password,
          'resource' => HOST
        },
        {
          accept: :json
        }
      )
      # TODO capture expiration time
      JSON.parse(response)['access_token']
    end

    def build_params(additional_params={}, api_version: DEFAULT_API_VERSION)
      {
        'api-version' => api_version,
      }.merge(additional_params)
    end

    def tenant_oauth_token_url(tenant:)
      "https://login.microsoftonline.com/#{ tenant }/oauth2/token"
    end

    def api_exception_trap(capture_exception)
      yield
    rescue RestClient::ExceptionWithResponse => e
      raise(e) unless capture_exception
      e.response
    end

    # REST wrappers

    def api_get(path:, params: {}, capture_exception: false, api_version: DEFAULT_API_VERSION)
      self.login() if @token.blank?
      response = api_exception_trap(capture_exception) do
        RestClient.get(
          HOST + "subscriptions/#{@subscription.value}" + path,
          {
            params: build_params(params, api_version: api_version),
            Authorization: "Bearer #{ @token }",
            accept: :json
          }
        )
      end
      response.body
    end

    def api_head(path:, params: {}, capture_exception: true, api_version: DEFAULT_API_VERSION)
      self.login() if @token.blank?
      api_exception_trap(capture_exception) do
        RestClient.head(
          HOST + "subscriptions/#{@subscription.value}" + path,
          {
            params: build_params(params, api_version: api_version),
            Authorization: "Bearer #{ @token }",
            accept: :json
          }
        )
      end
    end

    def api_post(path:, params: {}, body: '{}', capture_exception: false, api_version: DEFAULT_API_VERSION)
      self.login() if @token.blank?
      response = api_exception_trap(capture_exception) do
        RestClient.post(
          HOST + "subscriptions/#{ @subscription.value }" + path,
          body,
          {
            params: build_params(params, api_version: api_version),
            Authorization: "Bearer #{ @token }",
            content_type: :json,
            accept: :json
          }
        )
      end
      response.body
    end

    def api_put(path:, params: {}, body: '{}', capture_exception: false, api_version: DEFAULT_API_VERSION)
      self.login() if @token.blank?
      response = api_exception_trap(capture_exception) do
        RestClient.put(
          HOST + "subscriptions/#{ @subscription.value }" + path,
          body,
          {
            params: build_params(params, api_version: api_version),
            Authorization: "Bearer #{ @token }",
            content_type: :json,
            accept: :json
          }
        )
      end
      response.body
    end

    def api_delete(path:, params: {}, capture_exception: true, api_version: DEFAULT_API_VERSION)
      self.login() if @token.blank?
      api_exception_trap(capture_exception) do
        RestClient.delete(
          HOST + "subscriptions/#{ @subscription.value }" + path,
          {
            params: build_params(params, api_version: api_version),
            Authorization: "Bearer #{ @token }",
            accept: :json
          }
        )
      end
    end

    # Resource Groups

    def describe_resource_group(name:)
      api_get(path: "/resourcegroups/#{name}")
    end

    def resource_group_exists?(name:)
      response = api_head(path: "/resourcegroups/#{name}")
      (200..207).include?(response.code)
    end

    def create_resource_group(name:)
      api_put(
        path: "/resourcegroups/#{name}",
        body: {
          'location' => @region.value
        }.to_json
      )
    end

    def destroy_resource_group(name:)
      response = api_delete(
        path: "/resourcegroups/#{name}",
        params: {
          'forceDeletionTypes' => 'Microsoft.Compute/virtualMachines,Microsoft.Compute/virtualMachineScaleSets'
        }
      )
      (200..207).include?(response.code)
    end

    # AKS

    def get_kubernetes_versions()
      response = api_get(path: "/providers/Microsoft.ContainerService/locations/#{ @region.value }/kubernetesVersions")
      JSON.parse(response)['values'].map{|v| v['version'] }.sort
    end

    def create_cluster(name:, resource_group:, k8s_version:, vm_size:, node_count: 3, zones: %w(1 2 3))
      response = api_put(
        path: "/resourceGroups/#{ resource_group }/providers/Microsoft.ContainerService/managedClusters/#{ name }",
        body: {
          'location' => @region.value,
          'properties' => {
            'kubernetesVersion' => k8s_version,
            'dnsPrefix' => 'rancher-setup',
            'agentPoolProfiles' => [
              {
                'name' => 'nodepool1',
                'count' => node_count,
                'vmSize' => vm_size,
                'availabilityZones' => zones,
                'osType' => 'Linux',
                'type' => 'VirtualMachineScaleSets',
                'enableNodePublicIP' => false,
                'mode' => 'System'
              }
            ],
            'networkProfile' => {
              'loadBalancerSku'=> 'standard',
              'outboundType' => 'loadBalancer',
            },
            servicePrincipalProfile: {
              'clientId' => @credential.app_id,
              'secret' => @credential.password
            }
          }
        }.to_json,
        capture_exception: true,
        api_version: AKS_API_VERSION
      )
    end

    def describe_cluster(name:, resource_group:)
      api_get(
        path: "/resourceGroups/#{ resource_group }/providers/Microsoft.ContainerService/managedClusters/#{ name }"
      )
    end

    def update_kubeconfig(cluster:, resource_group:, kubeconfig: Rails.configuration.kubeconfig)
      response = api_post(path: "/resourceGroups/#{ resource_group }/providers/Microsoft.ContainerService/managedClusters/#{ cluster }/listClusterAdminCredential")
      File.write(
        kubeconfig,
        Base64.decode64(JSON.parse(response)['kubeconfigs'].first['value'])
      )
    end

    # DNS zones

    def find_resource_group_for_dns_zone(zone:)
      response = api_get(
        path: '/providers/Microsoft.Network/dnszones',
        api_version: DNS_API_VERSION
      )
      id = JSON.parse(response)['value'].find{|resource| resource['name'] == zone }['id']
      id.match(/resourceGroups\/(?<resourcegroup>.+)\/providers/)[:resourcegroup]
    rescue RestClient::ExceptionWithResponse, NoMethodError
      nil
    end

    def create_dns_A_record(resource_group:, record:, domain:, target:)
      api_put(
        path: "/resourceGroups/#{ resource_group }/providers/Microsoft.Network/dnsZones/#{ domain }/A/#{ record }",
        body: {
          'properties': {
            'TTL' => 3600,
            'ARecords': [
              {
                'ipv4Address' => target
              }
            ]
          }
        }.to_json,
        api_version: DNS_API_VERSION
      )
    end

    def create_dns_record(resource_group:, record_type:, record:, domain:, target:)
      case record_type
      when 'A'
        create_dns_A_record(
          resource_group: resource_group,
          record: record,
          domain: domain,
          target: target
        )
      end
    end

    def describe_dns_record(resource_group:, record_type:, record:, domain:)
      api_get(
        path: "/resourceGroups/#{ resource_group }/providers/Microsoft.Network/dnsZones/#{ domain }/#{ record_type }/#{ record }",
        api_version: DNS_API_VERSION
      )
    end

    def destroy_dns_record(resource_group:, record_type:, record:, domain:)
      api_delete(
        path: "/resourceGroups/#{ resource_group }/providers/Microsoft.Network/dnsZones/#{ domain }/#{ record_type }/#{ record }",
        api_version: DNS_API_VERSION
      )
    end

    # Preflight checks & config options

    def list_sizes(region: @region)
      response = api_get(
        path: "/providers/Microsoft.Compute/locations/#{ region }/vmSizes",
        api_version: VM_SIZES_API_VERSION
      )
      JSON.parse(response)['value']
    end

    def describe_instance_type(instance_type, tmp_path: 'tmp/skus.json')
      self.login() if @token.blank?
      response = api_exception_trap(true) do
        RestClient.get(
          HOST + "subscriptions/#{@subscription.value}/providers/Microsoft.Compute/skus",
          {
            params: {
              'api-version' => DEFAULT_API_VERSION,
              '$filter' => "location eq '#{ @region }'"
            },
            Authorization: "Bearer #{ @token }",
            accept: :json
          }
        )
      end
      File.write(Rails.root.join(tmp_path), response.body)
      JMESPath.search("value[?name=='#{ instance_type }']", Rails.root.join(tmp_path)).first
    end

    def list_vcpu_usage(family:)
      response = api_get(
        path: "/providers/Microsoft.Compute/locations/#{ @region }/usages"
      )
      JSON.parse(response)['value'].find{|r| r['name']['value'] == family }
    end

    def list_network_usage(value:)
      response = api_get(
        path: "/providers/Microsoft.Network/locations/#{ @region }/usages",
        api_version: NETWORK_API_VERSION
      )
      JSON.parse(response)['value'].find{|r| r['name']['value'] == value }
    end
  end
end
